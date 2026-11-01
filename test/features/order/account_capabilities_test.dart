import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sixam_mart_delivery/features/my_account/controllers/my_account_controller.dart';
import 'package:sixam_mart_delivery/features/my_account/domain/services/my_account_service_interface.dart';
import 'package:sixam_mart_delivery/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart_delivery/features/profile/domain/models/profile_model.dart';
import 'package:sixam_mart_delivery/features/profile/domain/services/profile_service_interface.dart';

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);
  for (final delivery in [false, true]) {
    for (final ride in [false, true]) {
      test('resolved capabilities delivery=$delivery ride=$ride select only supported APIs', () async {
        final profile = _ProfileController(ProfileModel(isDeliveryOn: delivery, isRideOn: ride));
        Get.put<ProfileController>(profile);
        final service = _AccountService();
        final account = MyAccountController(myAccountServiceInterface: service);
        await account.refreshIncomeStatements();
        expect(profile.resolved, isTrue);
        expect(service.deliveryCalls, delivery ? 1 : 0);
        expect(service.rideCalls, ride ? 1 : 0);
        await account.getRideIncomeStatement(2);
        await account.getDeliveryIncomeStatement(2);
        expect(service.deliveryCalls, delivery ? 2 : 0);
        expect(service.rideCalls, ride ? 2 : 0);
      });
    }
  }
}

class _ProfileController extends ProfileController {
  final ProfileModel model;
  bool resolved = false;
  _ProfileController(this.model) : super(profileServiceInterface: _ProfileService());
  @override
  ProfileModel? get profileModel => resolved ? model : null;
  @override
  Future<ProfileModel?> getProfile() async { resolved = true; return model; }
}
class _ProfileService implements ProfileServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _AccountService implements MyAccountServiceInterface {
  int deliveryCalls = 0;
  int rideCalls = 0;
  @override
  Future<Response> getRideIncomeStatement(int offset) async {
    rideCalls++;
    return const Response(statusCode: 200, body: {'data': []});
  }
  @override
  Future<Response> getDeliveryIncomeStatement(int offset) async {
    deliveryCalls++;
    return const Response(statusCode: 200, body: {'data': []});
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
