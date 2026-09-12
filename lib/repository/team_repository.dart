import 'package:cloud_firestore/cloud_firestore.dart';

class TeamRepository {
  /// Generic function — kisi bhi collection (managers/riders/customers) ka stream deta hai
  Stream<QuerySnapshot> getCollectionStream(String collectionName) {
    return FirebaseFirestore.instance.collection(collectionName).snapshots();
  }
}