import 'dart:async';
import 'dart:io';

import 'package:labellab_mobile/data/local/classifcation_provider.dart';
import 'package:labellab_mobile/data/local/project_provider.dart';
import 'package:labellab_mobile/data/local/user_provider.dart';
import 'package:labellab_mobile/data/remote/dto/google_user_request.dart';
import 'package:labellab_mobile/data/remote/dto/login_response.dart';
import 'package:labellab_mobile/data/remote/labellab_api.dart';
import 'package:labellab_mobile/data/remote/labellab_api_impl.dart';
import 'package:labellab_mobile/data/remote/dto/api_response.dart';
import 'package:labellab_mobile/model/auth_user.dart';
import 'package:labellab_mobile/model/classification.dart';
import 'package:labellab_mobile/model/comment.dart';
import 'package:labellab_mobile/model/group.dart';
import 'package:labellab_mobile/model/image.dart';
import 'package:labellab_mobile/model/issue.dart';
import 'package:labellab_mobile/model/label.dart';
import 'package:labellab_mobile/model/label_selection.dart';
import 'package:labellab_mobile/model/location.dart';
import 'package:labellab_mobile/model/log.dart';
import 'package:labellab_mobile/model/message.dart';
import 'package:labellab_mobile/model/ml_model.dart';
import 'package:labellab_mobile/model/project.dart';
import 'package:labellab_mobile/model/register_user.dart';
import 'package:labellab_mobile/model/team.dart';
import 'package:labellab_mobile/model/upload_image.dart';
import 'package:labellab_mobile/model/user.dart';
import 'package:labellab_mobile/screen/train/dialogs/dto/model_dto.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local/issue_provider.dart';
// import 'package:charts_flutter/flutter.dart' as charts;

class Repository {
  LabelLabAPI _api;
  ProjectProvider _projectProvider;
  ClassificationProvider _classificationProvider;
  UserProvider _userProvider;
  IssueProvider _issueProvider;
  static const ERROR_MESSAGE = "Can't connect to Server";

  String? accessToken;

  Future<bool> initToken() {
    return SharedPreferences.getInstance().then((pref) {
      String? accessTokenStored = pref.getString("access_token");
      String? refreshTokenStored = pref.getString("refresh_token");

      if (accessTokenStored != null && refreshTokenStored != null) {
        accessToken = accessTokenStored;
        return true;
      } else {
        return false;
      }
    });
  }

  Future<LoginResponse> login(AuthUser user) {
    return _api.login(user).then((response) => _storeTokens(response));
  }

  Future<LoginResponse> loginWithGoogle(GoogleUserRequest user) {
    return _api
        .loginWithGoogle(user)
        .then((response) => _storeTokens(response));
  }

  Future<LoginResponse> loginWithGithub(String code) {
    return _api
        .loginWithGithub(code)
        .then((response) => _storeTokens(response));
  }

  LoginResponse _storeTokens(LoginResponse response) {
    this.accessToken = response.accessToken;
    SharedPreferences.getInstance().then((pref) {
      pref.setString("access_token", response.accessToken!);
      pref.setString("refresh_token", response.refreshToken!);
    });
    return response;
  }

  Future<bool> refreshToken() {
    return SharedPreferences.getInstance().then((pref) {
      final String? refreshToken = pref.getString('refresh_token');

      return _api.refreshToken(refreshToken).then((response) {
        this.accessToken = response.accessToken;
        pref.setString("access_token", response.accessToken!);
        Logger().i("Token updated");
        return true;
      }).catchError((err) {
        Logger().e(err);
        return false;
      });
    });
  }

  Future<void> logout() {
    this.accessToken = null;
    return SharedPreferences.getInstance().then((pref) async {
      pref.remove("access_token");
      pref.remove("refresh_token");

      await _userProvider.delete();
    });
  }

  Future<LoginResponse> register(RegisterUser user) {
    return _api.register(user).then((response) {
      if (response.errField == null) {
        return login(user);
      } else
        throw Exception(response.msg);
    });
  }

  Future<User?> usersInfoLocal() {
    return _userProvider.getUser();
  }

  Future<User> usersInfo() {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.usersInfo(accessToken).then((user) async {
      await _userProvider.insert(user);
      return user;
    });
  }

  Future<List<User>> searchUser(String email) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.searchUser(accessToken, email);
  }

  Future<List<User>> getUsers() {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getUsers(accessToken);
  }

  Future<ApiResponse> uploadUserImage(File image) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.uploadUserImage(accessToken, image);
  }

  Future<ApiResponse> editInfo(String username) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.editInfo(accessToken, username);
  }

  Future<ApiResponse> updatePassword(
      String currentPassword, String newPassword) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.updatePassword(accessToken, currentPassword, newPassword);
  }

  // Project
  Future<ApiResponse> createProject(Project project) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.createProject(accessToken, project);
  }

  Future<Project> getProject(String? id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getProject(accessToken, id);
  }

  Future<List<Project>> getProjectsLocal() {
    return _projectProvider.open().then((_) {
      return _projectProvider.getProjects().then((projects) {
        _projectProvider.close();
        return projects!;
      });
    });
  }

  Future<List<Project>> getProjects() {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getProjects(accessToken).then((projects) {
      // _projectProvider.open().then((_) async {
      //   await _projectProvider.replaceProjects(projects);
      //   _projectProvider.close();
      // });
      return projects;
    });
  }

  Future<ApiResponse> updateProject(Project project) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.updateProject(accessToken, project);
  }

  Future<ApiResponse?> deleteProject(String? id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.deleteProject(accessToken, id);
  }

  Future<ApiResponse?> addMember(
      String projectId, String email, String teamname, String role) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.addMember(accessToken, projectId, email, teamname, role);
  }

  Future<ApiResponse?> removeMember(String projectId, String? email) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.removeMember(accessToken, projectId, email);
  }

  Future<List<String>> getMemberRoles(String projectId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getMemberRoles(accessToken, projectId);
  }

  Future<ApiResponse> leaveProject(String projectId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.leaveProject(accessToken, projectId);
  }

  Future<ApiResponse> makeAdmin(String projectId, String memberEmail) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.makeAdmin(accessToken, projectId, memberEmail);
  }

  Future<ApiResponse> removeAdmin(String projectId, String memberEmail) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.removeAdmin(accessToken, projectId, memberEmail);
  }

  // Teams
  Future<ApiResponse> createTeam(
      String projectId, Map<String, dynamic> postData) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.createTeam(accessToken, projectId, postData);
  }

  Future<ApiResponse> updateTeam(
      String projectId, String teamId, String teamName, String role) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.updateTeam(accessToken, projectId, teamId, teamName, role);
  }

  Future<ApiResponse> deleteTeam(String projectId, String teamId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.deleteTeam(accessToken, projectId, teamId);
  }

  Future<Team> getTeamDetails(String projectId, String teamId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getTeamDetails(accessToken, projectId, teamId);
  }

  Future<ApiResponse> addTeamMember(
      String projectId, String teamId, String memberEmail) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.addTeamMember(accessToken, projectId, teamId, memberEmail);
  }

  Future<ApiResponse> removeTeamMember(
      String projectId, String teamId, String memberEmail) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.removeTeamMember(accessToken, projectId, teamId, memberEmail);
  }

  Future<List<Message>> getChatroomMessages(String teamId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getChatroomMessages(accessToken, teamId);
  }

  // Image
  Future<ApiResponse> uploadImage(String projectId, UploadImage image) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.uploadImage(accessToken, projectId, image);
  }

  Future<List<Image>> getImages(String projectId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getImages(accessToken, projectId);
  }

  Future<Image> getImage(String imageId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getImage(accessToken, imageId);
  }

  Future<ApiResponse> updateImage(
      String projectId, Image? image, List<LabelSelection?> selections) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.updateImage(accessToken, projectId, image, selections);
  }

  Future<ApiResponse> deleteImage(String projectId, String imageId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.deleteImage(accessToken, projectId, imageId);
  }

  Future<ApiResponse> deleteImages(String projectId, List<String?> imageIds) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.deleteImages(accessToken, projectId, imageIds);
  }

  Future<List<Location>> getImagesPath(String projectId, List<String?> ids) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getImagesPath(accessToken, projectId, ids);
  }

  // Logs
  Future<List<Log>> getProjectActivityLogs(String projectId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getProjectActivityLogs(accessToken, projectId);
  }

  Future<List<Log>> getCategorySpecificLogs(String projectId, String category) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getCategorySpecificLogs(accessToken, projectId, category);
  }

  Future<List<Log>> getMemberSpecificLogs(String projectId, String userEmail) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getMemberSpecificLogs(accessToken, projectId, userEmail);
  }

  Future<List<Log>> getEntitySpecificLogs(
      String projectId, String entityType, String entityId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getEntitySpecificLogs(
        accessToken, projectId, entityType, entityId);
  }

  // Group
  Future<ApiResponse> createGroup(String projectId, Group group) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.createGroup(accessToken, projectId, group);
  }

  Future<ApiResponse> addGroupImages(
      String projectId, String groupId, List<String?> images) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.addGroupImages(accessToken, projectId, groupId, images);
  }

  Future<ApiResponse> updateGroup(Group group) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.updateGroup(accessToken, group);
  }

  Future<Group> getGroup(String groupId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getGroup(accessToken, groupId);
  }

  // Label
  Future<ApiResponse> createLabel(String projectId, Label label) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.createLabel(accessToken, projectId, label);
  }

  Future<List<Label>> getLabels(String projectId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getLabels(accessToken, projectId);
  }

  Future<ApiResponse> updateLabel(String projectId, Label label) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.updateLabel(accessToken, projectId, label);
  }

  Future<ApiResponse> deleteLabel(String projectId, String? labelId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.deleteLabel(accessToken, projectId, labelId);
  }

  // Classification
  Future<Classification> classify(File image) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.classify(accessToken, image);
  }

  Future<List<Classification>> getClassifications() {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getClassifications(accessToken).then((classifications) {
      _classificationProvider.open().then((_) async {
        await _classificationProvider.replaceClassifications(classifications);
        _classificationProvider.close();
      });
      return classifications;
    });
  }

  Future<List<Classification>> getClassificationsLocal() {
    return _classificationProvider.open().then((_) {
      return _classificationProvider
          .getClassifications()
          .then((classifications) {
        _classificationProvider.close();
        return classifications!;
      });
    });
  }

  Future<Classification> getClassification(String id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getClassification(accessToken, id);
  }

  Future<Classification> getClassificationLocal(String id) {
    return _classificationProvider.open().then((_) {
      return _classificationProvider
          .getClassification(id)
          .then((classification) {
        _classificationProvider.close();
        return classification!;
      });
    });
  }

  Future<bool> deleteClassification(String? id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.deleteClassification(accessToken, id).then((res) {
      return _classificationProvider.open().then((_) {
        return _classificationProvider.delete(id).then((_) {
          _classificationProvider.close();
          return res.success!;
        });
      });
    });
  }

  Future<List<MlModel>> getModels(String projectId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getModels(accessToken, projectId);
  }

  Future<MlModel> getModel(String modelId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getModel(accessToken, modelId);
  }

  Future<List<MlModel>> getTrainedModels(String projectId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getTrainedModels(accessToken, projectId);
  }

  Future<ApiResponse> createModel(String projectId, MlModel model) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.createModel(accessToken, projectId, model);
  }

  Future<ApiResponse> updateModel(String projectId, MlModel model) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.updateModel(accessToken, projectId, model);
  }

  Future<ApiResponse> saveModel(
      String modelId, MlModel? model, ModelDto modelDto) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.saveModel(accessToken, modelId, model, modelDto);
  }

  Future<ApiResponse> trainModel(String modelId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.trainModel(accessToken, modelId);
  }

  Future<ApiResponse> deleteModel(String modelId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.deleteModel(accessToken, modelId);
  }

  //issue
  Future<List<Issue>> getIssuesLocal() {
    return _issueProvider.open().then((_) {
      return _issueProvider.getIssues().then((issues) {
        _issueProvider.close();
        return issues!;
      });
    });
  }

  Future<List<Issue>> getIssues(String? project_id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getIssues(accessToken, project_id).then((issues) {
      return issues;
    });
  }

  Future<Issue> getIssue(String? id, String? project_id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getIssue(accessToken, project_id, id);
  }

  Future<ApiResponse> createIssue(Issue issue) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.createIssue(accessToken, issue);
  }

  Future<ApiResponse> updateIssue(Issue issue) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.updateIssue(accessToken, issue);
  }

  Future<List<Issue>> getCategorySpecificIssue(
      String projectId, String category) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.getCategorySpecificIssue(accessToken, projectId, category);
  }

  Future<ApiResponse?> deleteIssue(String? id, String project_id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.deleteIssue(accessToken, id, project_id);
  }

  Future<ApiResponse?> assignIssue(
      String projectId, String issueId, String assigneeId) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.assignIssue(accessToken, projectId, issueId, assigneeId);
  }

  Future<ApiResponse> postComment(Comment comment, String issue_id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.postComment(accessToken, comment, issue_id);
  }

  Future<ApiResponse> updateComment(Comment comment, String issue_id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.updateComment(accessToken, issue_id, comment);
  }

  Future<ApiResponse?> deleteComment(Comment comment, String issue_id) {
    if (accessToken == null) return Future.error(ERROR_MESSAGE);
    return _api.deleteComment(accessToken, issue_id, comment);
  }

  // Singleton
  static final Repository _respository = Repository._internal();

  factory Repository() {
    return _respository;
  }

  Repository._internal()
      : _api = LabelLabAPIImpl(),
        _projectProvider = ProjectProvider(),
        _classificationProvider = ClassificationProvider(),
        _userProvider = UserProvider(),
        _issueProvider = IssueProvider();
}
