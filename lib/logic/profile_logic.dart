import '../repository/profile_repository.dart';

class ProfileService {
  final ProfileRepository _repo = ProfileRepository();

  Stream<OwnerProfileModel> get profileStream => _repo.getOwnerProfileStream();
}