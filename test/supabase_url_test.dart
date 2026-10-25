import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_stock/data/supabase_remote.dart';

void main() {
  test('l\'adresse du projet Supabase est nettoyée', () {
    const project = 'https://abcd.supabase.co';
    expect(projectUrl('https://abcd.supabase.co/rest/v1/'), project);
    expect(projectUrl(' https://abcd.supabase.co/ '), project);
    expect(projectUrl(project), project);
    expect(projectUrl(''), '');
  });
}
