import '../../features/news/data/datasources/news_remote_datasource.dart';
import '../../features/news/data/repositories/news_repository_impl.dart';
import '../../features/news/domain/repositories/news_repository.dart';
import '../../features/news/domain/usecases/get_news_articles.dart';
import '../../features/news/presentation/bloc/news_bloc.dart';
import '../network/dio_client.dart';

class Injection {
  static NewsBloc createNewsBloc({DioClient? dioClient}) {
    final NewsRemoteDataSource dataSource = NewsRemoteDataSourceImpl(dioClient: dioClient);
    final NewsRepository repository =
        NewsRepositoryImpl(remoteDataSource: dataSource);
    final useCase = GetNewsArticles(repository);
    return NewsBloc(getNewsArticles: useCase, newsRepository: repository);
  }

  static DioClient createDioClient() => DioClient();
}
