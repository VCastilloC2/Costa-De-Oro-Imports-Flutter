import 'package:costa_de_oro_imports/core/utils/formatters.dart';
import 'package:costa_de_oro_imports/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('requires a value', () {
      expect(Validators.email(null), 'El correo es obligatorio');
      expect(Validators.email('   '), 'El correo es obligatorio');
    });

    test('accepts common real-world addresses', () {
      for (final email in [
        'ana@costadeoro.com',
        'ana.perez+tienda@mail.co',
        'admin@sub.dominio.travel',
        '  ana@mail.com  ',
      ]) {
        expect(Validators.email(email), isNull, reason: email);
      }
    });

    test('rejects malformed addresses', () {
      for (final email in [
        'ana',
        'ana@',
        '@mail.com',
        'ana@mail',
        'a b@x.co',
      ]) {
        expect(Validators.email(email), 'Correo inválido', reason: email);
      }
    });
  });

  group('Validators.password', () {
    test('requires a value and a minimum length', () {
      expect(Validators.password(''), 'La contraseña es obligatoria');
      expect(Validators.password('abcd'), contains('al menos'));
      expect(Validators.password('abcde'), isNull);
    });

    test('confirmPassword compares with the current password', () {
      var current = 'secreta';
      final validate = Validators.confirmPassword(() => current);

      expect(validate(''), 'Debes confirmar la contraseña');
      expect(validate('otra'), 'Las contraseñas no coinciden');
      expect(validate('secreta'), isNull);

      current = 'cambiada';
      expect(validate('secreta'), 'Las contraseñas no coinciden');
    });
  });

  group('Formatters', () {
    test('money uses Colombian thousands separators and no decimals', () {
      final text = Formatters.money(1589420);
      expect(text, contains(r'$'));
      expect(text, contains('1.589.420'));
      expect(text, isNot(contains(',')));
    });

    test('compactMoney keeps small amounts exact', () {
      expect(Formatters.compactMoney(92000), Formatters.money(92000));
      expect(
        Formatters.compactMoney(5989420).length,
        lessThan(Formatters.money(5989420).length),
      );
    });

    test('monthShort returns Spanish abbreviations', () {
      expect(Formatters.monthShort(DateTime(2026, 1)), 'Ene');
      expect(Formatters.monthShort(DateTime(2026, 8)), 'Ago');
      expect(Formatters.monthShort(DateTime(2026, 12)), 'Dic');
    });

    test('initials uses name parts or the email user', () {
      expect(Formatters.initials('Ana Pérez'), 'AP');
      expect(Formatters.initials('ana pérez gómez'), 'AP');
      expect(Formatters.initials('admin@costadeoro.com'), 'A');
      expect(Formatters.initials(''), '?');
    });
  });
}
