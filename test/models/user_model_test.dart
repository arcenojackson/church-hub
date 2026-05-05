import 'package:flutter_test/flutter_test.dart';
import 'package:church_hub/src/modules/auth/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses phone and birthday', () {
      final json = {
        'id': 'u1',
        'name': 'João Silva',
        'email': 'joao@test.com',
        'role': 'member',
        'status': 'active',
        'phone': '+55 48 99999-0000',
        'birthday': {'_seconds': 820454400, '_nanoseconds': 0},
      };

      final user = UserModel.fromJson(json);

      expect(user.phone, '+55 48 99999-0000');
      expect(user.birthday, isNotNull);
      expect(user.birthday!.year, 1996);
    });

    test('fromJson works without phone and birthday', () {
      final json = {
        'id': 'u1',
        'name': 'João Silva',
        'email': 'joao@test.com',
        'role': 'member',
        'status': 'active',
      };

      final user = UserModel.fromJson(json);

      expect(user.phone, isNull);
      expect(user.birthday, isNull);
    });

    test('toJson includes phone and birthday when set', () {
      final birthday = DateTime(1996, 1, 1);
      final user = UserModel(
        id: 'u1',
        name: 'João Silva',
        email: 'joao@test.com',
        role: UserRole.member,
        status: UserStatus.active,
        phone: '+55 48 99999-0000',
        birthday: birthday,
      );

      final json = user.toJson();

      expect(json['phone'], '+55 48 99999-0000');
      expect(json['birthday'], isNotNull);
    });

    test('toJson omits phone and birthday when null', () {
      final user = UserModel(
        id: 'u1',
        name: 'João Silva',
        email: 'joao@test.com',
        role: UserRole.member,
        status: UserStatus.active,
      );

      final json = user.toJson();

      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('birthday'), isFalse);
    });

    test('copyWith preserves phone and birthday', () {
      final user = UserModel(
        id: 'u1',
        name: 'João',
        email: 'joao@test.com',
        role: UserRole.member,
        status: UserStatus.active,
        phone: '+55 48 99999-0000',
        birthday: DateTime(1996, 1, 1),
      );

      final updated = user.copyWith(name: 'João Silva');

      expect(updated.phone, '+55 48 99999-0000');
      expect(updated.birthday, DateTime(1996, 1, 1));
    });
  });
}
