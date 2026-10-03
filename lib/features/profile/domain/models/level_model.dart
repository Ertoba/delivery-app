class LevelModel {
  String? responseCode;
  String? message;
  int? totalSize;
  int? limit;
  int? offset;
  Data? data;
  List<String>? errors;

  LevelModel(
      {this.responseCode,
        this.message,
        this.totalSize,
        this.limit,
        this.offset,
        this.data,
        this.errors});

  LevelModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code'];
    message = json['message'];
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    data = json['data'] != null ?  Data.fromJson(json['data']) : null;
    errors = json['errors'] != null ? List<String>.from(json['errors'].map((e) => e.toString())) : null;
  }

}

class Data {
  NextLevel? nextLevel;
  CurrentLevel? currentLevel;
  CompletedCurrentLevelTarget? completedCurrentLevelTarget;
  bool? isCompleted;

  Data({this.nextLevel, this.currentLevel, this.completedCurrentLevelTarget,this.isCompleted});

  Data.fromJson(Map<String, dynamic> json) {
    nextLevel = json['next_level'] != null
        ?  NextLevel.fromJson(json['next_level'])
        : null;
    currentLevel = json['current_level'] != null
        ?  CurrentLevel.fromJson(json['current_level'])
        : null;
    completedCurrentLevelTarget = json['completed_current_level_target'] != null
        ?  CompletedCurrentLevelTarget.fromJson(
        json['completed_current_level_target'])
        : null;
    isCompleted = json['level_completed'];
  }

}

class NextLevel {
  String? id;
  int? sequence;
  String? name;
  String? rewardType;
  String? rewardAmount;
  String? image;
  double? targetedRide;
  double? targetedRidePoint;
  double? targetedAmount;
  double? targetedAmountPoint;
  double? targetedCancel;
  double? targetedCancelPoint;
  double? targetedReview;
  double? targetedReviewPoint;
  String? userType;
  int? isActive;

  NextLevel(
      {this.id,
        this.sequence,
        this.name,
        this.rewardType,
        this.rewardAmount,
        this.image,
        this.targetedRide,
        this.targetedRidePoint,
        this.targetedAmount,
        this.targetedAmountPoint,
        this.targetedCancel,
        this.targetedCancelPoint,
        this.targetedReview,
        this.targetedReviewPoint,
        this.userType,
        this.isActive});

  NextLevel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    sequence = json['sequence'];
    name = json['name'];
    rewardType = json['reward_type'];
    rewardAmount = json['reward_amount'];
    image = json['image'];
    targetedRide = double.tryParse(json['targeted_ride'].toString()) ?? 0;
    targetedRidePoint = double.tryParse(json['targeted_ride_point'].toString()) ?? 0;
    targetedAmount = double.tryParse(json['targeted_amount'].toString()) ?? 0;
    targetedAmountPoint = double.tryParse(json['targeted_amount_point'].toString()) ?? 0;
    targetedCancel = double.tryParse(json['targeted_cancel'].toString()) ?? 0;
    targetedCancelPoint = double.tryParse(json['targeted_cancel_point'].toString()) ?? 0;
    targetedReview = double.tryParse(json['targeted_review'].toString()) ?? 0;
    targetedReviewPoint = double.tryParse(json['targeted_review_point'].toString()) ?? 0;
    userType = json['user_type'];
    isActive = json['is_active'];
  }

}

class CurrentLevel {
  String? id;
  int? sequence;
  String? name;
  String? rewardType;
  String? rewardAmount;
  String? image;
  double? targetedRide;
  double? targetedRidePoint;
  double? targetedAmount;
  double? targetedAmountPoint;
  double? targetedCancel;
  double? targetedCancelPoint;
  double? targetedReview;
  double? targetedReviewPoint;
  String? userType;
  int? isActive;

  CurrentLevel(
      {this.id,
        this.sequence,
        this.name,
        this.rewardType,
        this.rewardAmount,
        this.image,
        this.targetedRide,
        this.targetedRidePoint,
        this.targetedAmount,
        this.targetedAmountPoint,
        this.targetedCancel,
        this.targetedCancelPoint,
        this.targetedReview,
        this.targetedReviewPoint,
        this.userType,
        this.isActive});

  CurrentLevel.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    sequence = json['sequence'];
    name = json['name'];
    rewardType = json['reward_type'];
    rewardAmount = json['reward_amount'];
    image = json['image'];
    targetedRide = double.tryParse(json['targeted_ride'].toString()) ?? 0;
    targetedRidePoint = double.tryParse(json['targeted_ride_point'].toString()) ?? 0;
    targetedAmount = double.tryParse(json['targeted_amount'].toString()) ?? 0;
    targetedAmountPoint = double.tryParse(json['targeted_amount_point'].toString()) ?? 0;
    targetedCancel = double.tryParse(json['targeted_cancel'].toString()) ?? 0;
    targetedCancelPoint = double.tryParse(json['targeted_cancel_point'].toString()) ?? 0;
    targetedReview = double.tryParse(json['targeted_review'].toString()) ?? 0;
    targetedReviewPoint = double.tryParse(json['targeted_review_point'].toString()) ?? 0;
    userType = json['user_type'];
    isActive = json['is_active'];
  }

}

class CompletedCurrentLevelTarget {
  double? reviewGiven;
  double? rideComplete;
  double? earningAmount;
  double? cancellationRate;
  double? reviewGivenPoint;
  double? rideCompletePoint;
  double? earningAmountPoint;
  double? cancellationRatePoint;

  CompletedCurrentLevelTarget(
      {this.reviewGiven,
        this.rideComplete,
        this.earningAmount,
        this.cancellationRate,
        this.reviewGivenPoint,
        this.cancellationRatePoint,
        this.earningAmountPoint,
        this.rideCompletePoint
      });

  CompletedCurrentLevelTarget.fromJson(Map<String, dynamic> json) {
    reviewGiven = double.tryParse(json['review_given'].toString()) ?? 0;
    rideComplete = double.tryParse(json['ride_complete'].toString()) ?? 0;
    earningAmount = double.tryParse(json['earning_amount'].toString()) ?? 0;
    cancellationRate = double.tryParse(json['cancellation_rate'].toString()) ?? 0;
    reviewGivenPoint = double.tryParse(json['review_given_point'].toString()) ?? 0;
    rideCompletePoint = double.tryParse(json['ride_complete_point'].toString()) ?? 0;
    earningAmountPoint = double.tryParse(json['earning_amount_point'].toString()) ?? 0;
    cancellationRatePoint = double.tryParse(json['cancellation_rate_point'].toString()) ?? 0;
  }

}
