import 'package:equatable/equatable.dart';

abstract class NewsEvent extends Equatable {
  const NewsEvent();
  @override
  List<Object?> get props => [];
}

class FetchNews extends NewsEvent {
  final int page;
  final int perPage;
  final String? feed; // latest | for_you
  final int? categoryId;
  final String? categoryName; // All, India, Tamil Nadu etc - server maps to id
  const FetchNews({this.page = 1, this.perPage = 10, this.feed, this.categoryId, this.categoryName});
  @override
  List<Object?> get props => [page, perPage, feed, categoryId, categoryName];
}

class FetchMoreNews extends NewsEvent {
  const FetchMoreNews();
}

class SwitchFeed extends NewsEvent {
  final String feed; // latest | for_you
  const SwitchFeed(this.feed);
  @override
  List<Object?> get props => [feed];
}

class FilterCategory extends NewsEvent {
  final String? categoryName; // null = All
  final int? categoryId;
  const FilterCategory({this.categoryName, this.categoryId});
  @override
  List<Object?> get props => [categoryName, categoryId];
}
