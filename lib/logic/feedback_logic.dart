import '../repository/feedback_repository.dart';

class FeedbackService {
  final FeedbackRepository _repo = FeedbackRepository();

  Stream<List<FeedbackModel>> get feedbackStreamOrdered =>
      _repo.getFeedbackStreamOrdered();

  Stream<List<FeedbackModel>> get feedbackStreamUnordered =>
      _repo.getFeedbackStreamUnordered();

  // 👈 NEW: resolves customer name (and branchId) for a review via its orderId
  Future<Map<String, String>> getOrderInfo(String orderId) =>
      _repo.getOrderInfo(orderId);

  /// Average rating nikalne ka business logic yahan hai
  double calculateAverageRating(List<FeedbackModel> feedbacks) {
    final ratedItems = feedbacks.where((f) => f.rating > 0).toList();
    if (ratedItems.isEmpty) return 0;
    final total = ratedItems.fold<double>(0, (sum, f) => sum + f.rating);
    return total / ratedItems.length;
  }
}