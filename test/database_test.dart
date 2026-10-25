import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/database.dart';

void main() {
  late AppDatabase db;
  late Product maillot;

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    maillot = await db.addProduct(
      name: 'Maillot Cameroun domicile 2024 M',
      category: Category.maillot,
      alertThreshold: 2,
    );
  });

  tearDown(() => db.close());

  test('un nouveau produit a un stock de 0', () async {
    expect(await db.stockOf(maillot.id), 0);
  });

  test('le stock vaut les entrées moins les sorties', () async {
    await db.receive(maillot.id, 10);
    await db.sell(maillot.id, 3);
    await db.lose(maillot.id, 1);
    await db.receive(maillot.id, 2);
    expect(await db.stockOf(maillot.id), 8);
  });

  test('une vente au-delà du stock est refusée et ne change rien', () async {
    await db.receive(maillot.id, 2);
    await expectLater(db.sell(maillot.id, 3), throwsA(isA<NotEnoughStock>()));
    expect(await db.stockOf(maillot.id), 2);
  });

  test('une quantité nulle ou négative est refusée', () async {
    expect(() => db.receive(maillot.id, 0), throwsArgumentError);
    expect(() => db.sell(maillot.id, -1), throwsArgumentError);
  });

  test('annuler une vente remet le stock et garde la trace', () async {
    await db.receive(maillot.id, 5);
    final vente = await db.sell(maillot.id, 2);
    final correction = await db.undo(vente.id);

    expect(await db.stockOf(maillot.id), 5);
    expect(correction.type, MovementType.correction);
    expect(correction.cancelsId, vente.id);
    expect(await db.select(db.movements).get(), hasLength(3));
  });

  test('un mouvement ne peut être annulé qu\'une fois', () async {
    final arrivage = await db.receive(maillot.id, 5);
    await db.undo(arrivage.id);
    await expectLater(db.undo(arrivage.id), throwsStateError);
    expect(await db.stockOf(maillot.id), 0);
  });

  test('modifier un produit garde son stock', () async {
    await db.receive(maillot.id, 4);
    await db.updateProduct(maillot.copyWith(name: 'Maillot Cameroun domicile 2024 L'));

    final lignes = await db.watchStock().first;
    expect(lignes.single.product.name, 'Maillot Cameroun domicile 2024 L');
    expect(lignes.single.quantity, 4);
  });

  test('un produit archivé disparaît de la liste', () async {
    await db.archiveProduct(maillot.id);
    expect(await db.watchStock().first, isEmpty);
  });

  test('la recherche ignore les majuscules', () async {
    await db.addProduct(name: 'Tissage lisse 18 pouces', category: Category.meche);
    final resultat = await db.watchStock(search: 'TISSAGE').first;
    expect(resultat.map((l) => l.product.name), ['Tissage lisse 18 pouces']);
  });

  test('la liste du stock signale ruptures et seuils bas', () async {
    final meche = await db.addProduct(name: 'Tissage lisse 18 pouces', category: Category.meche);
    await db.receive(maillot.id, 2);

    final lignes = await db.watchStock().first;
    final parNom = {for (final l in lignes) l.product.name: l};

    expect(parNom[maillot.name]!.quantity, 2);
    expect(parNom[maillot.name]!.isLow, isTrue);
    expect(parNom[meche.name]!.isOut, isTrue);
  });

  test('l\'historique liste les mouvements du plus récent au plus ancien', () async {
    await db.receive(maillot.id, 5);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final vente = await db.sell(maillot.id, 2);

    final historique = await db.watchHistory().first;
    expect(historique.map((h) => h.movement.type), [MovementType.sold, MovementType.received]);
    expect(historique.first.movement.id, vente.id);
    expect(historique.first.product.name, maillot.name);
  });

  test('l\'historique signale les saisies annulées', () async {
    final vente = await db.receive(maillot.id, 5).then((_) => db.sell(maillot.id, 1));
    await db.undo(vente.id);

    final historique = await db.watchHistory().first;
    final original = historique.singleWhere((h) => h.movement.id == vente.id);
    final correction = historique.singleWhere((h) => h.movement.type == MovementType.correction);
    expect(original.cancelled, isTrue);
    expect(original.canUndo, isFalse);
    expect(correction.canUndo, isFalse);
  });

  test('l\'historique se filtre par produit et par date', () async {
    final autre = await db.addProduct(name: 'Closure', category: Category.meche);
    await db.receive(maillot.id, 1);
    await db.receive(autre.id, 1);

    expect(await db.watchHistory(productId: autre.id).first, hasLength(1));
    final demain = DateTime.now().add(const Duration(days: 1));
    expect(await db.watchHistory(since: demain).first, isEmpty);
  });

  test('la liste à recommander contient ruptures et seuils bas', () async {
    final bien = await db.addProduct(name: 'Bien fourni', category: Category.autre);
    await db.receive(bien.id, 50);
    await db.receive(maillot.id, 1); // seuil 2

    final liste = await db.watchToReorder().first;
    expect(liste.map((l) => l.product.name), [maillot.name]);
  });

  test('annuler une réception déjà vendue est refusé', () async {
    final arrivage = await db.receive(maillot.id, 3);
    await db.sell(maillot.id, 2);
    await expectLater(db.undo(arrivage.id), throwsA(isA<NotEnoughStock>()));
    expect(await db.stockOf(maillot.id), 1);
  });

  test('totaux de l\'historique : entrées et sorties, saisies annulées exclues', () async {
    final p = await db.addProduct(name: 'Jus de gingembre', category: Category.autre);
    await db.receive(p.id, 10);
    final erreur = await db.receive(p.id, 5);
    await db.undo(erreur.id);
    await db.sell(p.id, 3);
    await db.lose(p.id, 1);

    final totals = await db.watchTotals().first;
    expect(totals.entered, 10);
    expect(totals.removed, 4);

    final entries = await db.watchHistory(direction: MovementDirection.entries).first;
    expect(entries.map((e) => e.movement.delta), unorderedEquals([5, 10]));
    final exits = await db.watchHistory(direction: MovementDirection.exits).first;
    expect(exits.map((e) => e.movement.type), unorderedEquals([MovementType.loss, MovementType.sold]));

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    expect((await db.watchTotals(since: tomorrow).first).entered, 0);
  });

  test('un produit créé avec une quantité de départ a sa première réception', () async {
    final p = await db.addProduct(
        name: 'Jus de mangue', category: Category.autre, purchasePriceCents: 120, initialQuantity: 24);
    expect(await db.stockOf(p.id), 24);
    final history = await db.watchHistory(productId: p.id).first;
    expect(history.single.movement.type, MovementType.received);
    expect(history.single.movement.unitPriceCents, 120);
  });

  test('inventaire : l\'écart compté est enregistré, et peut être annulé', () async {
    final p = await db.addProduct(name: 'Maillot OM M', category: Category.autre, initialQuantity: 10);
    final ecart = await db.adjustTo(p.id, 7, note: 'compté samedi');
    expect(ecart!.delta, -3);
    expect(ecart.type, MovementType.adjustment);
    expect(await db.stockOf(p.id), 7);
    expect(await db.adjustTo(p.id, 7), isNull, reason: 'compte juste : rien à enregistrer');

    await db.undo(ecart.id);
    expect(await db.stockOf(p.id), 10);
    // L'inventaire n'est ni une entrée ni une sortie dans les totaux.
    final totals = await db.watchTotals().first;
    expect((totals.entered, totals.removed), (10, 0));
  });

  test('archiver puis restaurer un produit', () async {
    final p = await db.addProduct(name: 'Perruque', category: Category.autre, initialQuantity: 2);
    await db.archiveProduct(p.id);
    expect(await db.watchStock(search: 'Perruque').first, isEmpty);
    expect((await db.watchArchived().first).single.quantity, 2);
    await db.restoreProduct(p.id);
    expect((await db.watchStock(search: 'Perruque').first).single.quantity, 2);
    expect(await db.watchArchived().first, isEmpty);
  });

  test('tri du stock par quantité', () async {
    await db.addProduct(name: 'Jus B', category: Category.autre, initialQuantity: 5);
    await db.addProduct(name: 'Jus A', category: Category.autre, initialQuantity: 9);
    await db.addProduct(name: 'Jus C', category: Category.autre);
    Future<List<String>> names(StockSort sort) async =>
        [for (final l in await db.watchStock(search: 'Jus', sort: sort).first) l.product.name];
    expect(await names(StockSort.name), ['Jus A', 'Jus B', 'Jus C']);
    expect(await names(StockSort.quantityAsc), ['Jus C', 'Jus B', 'Jus A']);
    expect(await names(StockSort.quantityDesc), ['Jus A', 'Jus B', 'Jus C']);
  });

  test('un produit supprimé disparaît partout, et peut revenir', () async {
    final p = await db.addProduct(name: 'Jus mangue', category: Category.autre, initialQuantity: 6);
    await db.sell(p.id, 2);
    await db.receive(maillot.id, 3);

    await db.deleteProduct(p.id);
    expect(await db.watchStock(search: 'Jus').first, isEmpty);
    expect(await db.watchArchived().first, isEmpty);
    expect((await db.watchHistory().first).map((e) => e.product.id), everyElement(maillot.id));
    final totals = await db.watchTotals().first;
    expect((totals.entered, totals.removed), (3, 0));

    await db.undeleteProduct(p.id);
    expect((await db.watchStock(search: 'Jus').first).single.quantity, 4);
    expect((await db.watchTotals().first).entered, 9);
  });

  test('supprimer un produit archivé le retire aussi des archives', () async {
    await db.archiveProduct(maillot.id);
    await db.deleteProduct(maillot.id);
    expect(await db.watchArchived().first, isEmpty);
  });
}
