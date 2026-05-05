import 'package:flutter_test/flutter_test.dart';
import 'package:church_hub/src/modules/profiles/models/profile_model.dart';
import 'package:church_hub/src/shared/permissions/app_permission.dart';

void main() {
  group('ProfileModel', () {
    test('can() returns true for isAdminRole regardless of permissions', () {
      final adminProfile = ProfileModel(
        id: 'admin',
        name: 'Admin',
        permissions: {AppPermission.planEvents: false},
        isAdminRole: true,
      );
      expect(adminProfile.can(AppPermission.planEvents), isTrue);
    });

    test('can() returns true when permission is explicitly true', () {
      final profile = ProfileModel(
        id: 'lider',
        name: 'Líder de Louvor',
        permissions: {AppPermission.planEvents: true},
      );
      expect(profile.can(AppPermission.planEvents), isTrue);
    });

    test('can() returns false when permission is explicitly false', () {
      final profile = ProfileModel(
        id: 'member',
        name: 'Membro',
        permissions: {AppPermission.planEvents: false},
      );
      expect(profile.can(AppPermission.planEvents), isFalse);
    });

    test('can() returns false for unknown permission', () {
      final profile = ProfileModel(
        id: 'member',
        name: 'Membro',
        permissions: {},
      );
      expect(profile.can('unknown_permission'), isFalse);
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': 'lider',
        'name': 'Líder de Louvor',
        'isAdminRole': false,
        'isDefault': false,
        'permissions': {
          'plan_events': true,
          'view_musics': true,
        },
      };
      final profile = ProfileModel.fromJson(json);
      expect(profile.name, 'Líder de Louvor');
      expect(profile.can(AppPermission.planEvents), isTrue);
      expect(profile.can(AppPermission.editMusics), isFalse);
    });

    test('toJson round-trips correctly', () {
      final profile = ProfileModel(
        id: 'lider',
        name: 'Líder',
        permissions: {AppPermission.planEvents: true},
        isAdminRole: false,
        isDefault: false,
      );
      final json = profile.toJson();
      final restored = ProfileModel.fromJson({'id': 'lider', ...json});
      expect(restored.name, profile.name);
      expect(restored.can(AppPermission.planEvents), isTrue);
    });
  });
}
