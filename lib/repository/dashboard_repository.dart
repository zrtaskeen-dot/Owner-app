import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Live Orders Stream (Revenue & Total Orders)
  Stream<QuerySnapshot> fetchRawOrdersSnapshot() {
    try {
      return _firestore.collection('orders').snapshots();
    } catch (e) {
      print('Repository - fetchRawOrdersSnapshot error: $e');
      rethrow;
    }
  }

  // 2. One-time Fetch for Best Selling Items
  Future<QuerySnapshot> fetchRawOrdersFuture() {
    try {
      return _firestore.collection('orders').get();
    } catch (e) {
      print('Repository - fetchRawOrdersFuture error: $e');
      rethrow;
    }
  }

  // 3. Dynamic Counter Stream (Customers, Riders, Managers)
  // NOTE: These must match your exact Firestore collection names
  Stream<QuerySnapshot> fetchCollectionSnapshot(String path) {
    try {
      return _firestore.collection(path).snapshots();
    } catch (e) {
      print('Repository - fetchCollectionSnapshot($path) error: $e');
      rethrow;
    }
  }

  // 4. Restaurant Info Stream (single branch document)
  // NOTE: Change 'main_branch' to your exact document ID in Firestore
  Stream<DocumentSnapshot> fetchRestaurantDocument() {
    try {
      return _firestore
          .collection('restaurant_info')
          .doc('main_branch') // verify this doc ID in Firestore console
          .snapshots();
    } catch (e) {
      print('Repository - fetchRestaurantDocument error: $e');
      rethrow;
    }
  }

  // 5. All Branches Stream (every document in restaurant_info)
  // Used for the branch overview list, which needs more than one branch.
  Stream<QuerySnapshot> fetchAllBranchesSnapshot() {
    try {
      return _firestore.collection('restaurant_info').snapshots();
    } catch (e) {
      print('Repository - fetchAllBranchesSnapshot error: $e');
      rethrow;
    }
  }
}