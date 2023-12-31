import 'dart:async';

import 'package:dio/dio.dart';
import 'package:labellab_mobile/data/repository.dart';
import 'package:labellab_mobile/model/issue.dart';
import 'package:labellab_mobile/screen/issue/issue_activity/issue_activity_state.dart';


class IssueActivityBloc {
  Repository _repository = Repository();

  List<Issue> _issues = [];
  bool _isLoading = false;
  String _projectId;

  IssueActivityBloc(this._projectId) {
    _loadIssues(_projectId);
  }

  void refresh() {
    _loadIssues(_projectId);
  }


  // Issue stream
  StreamController<IssueActivityState> _issueController =
      StreamController<IssueActivityState>();

  Stream<IssueActivityState> get issues => _issueController.stream;

  void _loadIssues(String projectId) {
    if (_isLoading) return;
    _isLoading = true;
    _setState(IssueActivityState.loading());
    _repository.getIssuesLocal().then((issues) {
      this._issues = issues;
      _setState(IssueActivityState.loading());
    });
    _repository.getIssues(projectId).then((issues) {
      this._issues = issues;
      _setState(IssueActivityState.success(_issues));
        _isLoading = false;
    }).catchError((err) {
      if (err is DioError) {
        _setState(
            IssueActivityState.error(err.message.toString(),));
      } else {
        _issueController
            .add(IssueActivityState.error(err.toString(), ));
      }
      _isLoading = false;
    });
  }

  void setCategoryIssues(List<Issue> issues) {
    this._issues = [...issues];
    this._setState(IssueActivityState.success(this._issues));
  }

  _setState(IssueActivityState state) {
    if (!_issueController.isClosed) _issueController.add(state);
  }

  void dispose() {
    _issueController.close();
  }

  String get projectId => this._projectId;
}
