import 'package:cloud_firestore/cloud_firestore.dart';
// Update this path to match your actual folder structure
import 'package:owner_app/repository/dashboard_repository.dart';

class DashboardController {
  final DashboardRepository _repository = DashboardRepository();

  // 1. Orders stream for Revenue & Total Orders
  Stream<QuerySnapshot> get ordersStream => _repository.fetchRawOrdersSnapshot();

  // 2. Counter streams for Customers, Riders, Managers
  Stream<QuerySnapshot> getCollectionStream(String path) =>
      _repository.fetchCollectionSnapshot(path);

  // 3. Restaurant open/close info stream
  Stream<DocumentSnapshot> get restaurantInfoStream =>
      _repository.fetchRestaurantDocument();
}