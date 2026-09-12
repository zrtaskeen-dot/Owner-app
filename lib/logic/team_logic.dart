import 'package:cloud_firestore/cloud_firestore.dart';
import '../repository/team_repository.dart'; // Path check kar lena

class TeamService {
  final TeamRepository _repo = TeamRepository();

  Stream<QuerySnapshot> getTeamStream(String collectionName) {
    return _repo.getCollectionStream(collectionName);
  }
}