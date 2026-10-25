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
}
