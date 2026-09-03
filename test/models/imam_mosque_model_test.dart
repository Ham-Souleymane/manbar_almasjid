import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manbar_almasjid/features/registration/domain/imam_model.dart';
import 'package:manbar_almasjid/features/registration/domain/imam_status.dart';
import 'package:manbar_almasjid/features/registration/domain/mosque_model.dart';

void main() {
  group('ImamModel Tests', () {
    test('Defaults and backward compatibility with legacy fields', () {
      final now = DateTime.now();
      final imam = ImamModel(
        id: 'imam_123',
        fullName: 'الشيخ أحمد',
        phone: '+966500000000',
        email: 'imam@masjid.com',
        status: ImamStatus.verified,
        createdAt: now,
      );

      expect(imam.acceptingQuestions, true);
      expect(imam.specialties, isEmpty);
      expect(imam.bio, '');
      expect(imam.responseTime, '');
      expect(imam.allowPrivateQuestions, true);

      final map = imam.toFirestore();
      expect(map['fullName'], 'الشيخ أحمد');
      expect(map['acceptingQuestions'], true);
      expect(map['allowPrivateQuestions'], true);
    });

    test('CopyWith Ask Sheikh properties', () {
      final now = DateTime.now();
      final imam = ImamModel(
        id: 'imam_123',
        fullName: 'الشيخ أحمد',
        phone: '+966500000000',
        email: 'imam@masjid.com',
        status: ImamStatus.verified,
        createdAt: now,
      );

      final updated = imam.copyWith(
        acceptingQuestions: false,
        specialties: ['الفقه', 'القرآن والتجويد'],
        bio: 'خريج جامعة الأزهر',
        responseTime: 'خلال 24 ساعة',
        allowPrivateQuestions: false,
      );

      expect(updated.acceptingQuestions, false);
      expect(updated.specialties, ['الفقه', 'القرآن والتجويد']);
      expect(updated.bio, 'خريج جامعة الأزهر');
      expect(updated.responseTime, 'خلال 24 ساعة');
      expect(updated.allowPrivateQuestions, false);
    });
  });

  group('MosqueModel Tests', () {
    test('Defaults and unclaimed mosque detection', () {
      final now = DateTime.now();
      final unclaimedMosque = MosqueModel(
        id: 'mosque_999',
        name: 'مسجد النور',
        country: 'المملكة العربية السعودية',
        city: 'الرياض',
        address: 'حي الياسمين',
        geopoint: const GeoPoint(24.7136, 46.6753),
        contactPhone: '',
        imamId: '',
        verified: false,
        createdAt: now,
        hasImam: false,
        addedBy: 'أحد المصلين',
      );

      expect(unclaimedMosque.isClaimed, false);
      expect(unclaimedMosque.acceptingQuestions, true);
      expect(unclaimedMosque.addedBy, 'أحد المصلين');

      final claimed = unclaimedMosque.copyWith(
        imamId: 'imam_123',
        imamName: 'الشيخ أحمد',
        hasImam: true,
      );

      expect(claimed.isClaimed, true);
      expect(claimed.imamId, 'imam_123');
      expect(claimed.imamName, 'الشيخ أحمد');
    });
  });
}
