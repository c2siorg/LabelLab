import 'dart:convert';
import 'dart:io';

// import 'package:charts_common/src/data/series.dart';
import 'package:dio/dio.dart';
import 'package:labellab_mobile/data/interceptor/backend_url_interceptor.dart';
import 'package:labellab_mobile/data/interceptor/token_interceptor.dart';
import 'package:labellab_mobile/data/remote/dto/google_user_request.dart';
import 'package:labellab_mobile/data/remote/dto/login_response.dart';
import 'package:labellab_mobile/data/remote/dto/refresh_response.dart';
import 'package:labellab_mobile/data/remote/dto/register_response.dart';
import 'package:labellab_mobile/data/remote/fake_server/fake_server.dart';
import 'package:labellab_mobile/data/remote/labellab_api.dart';
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
import 'package:labellab_mobile/model/mapper/ml_model_mapper.dart';
import 'package:labellab_mobile/model/message.dart';
import 'package:labellab_mobile/model/ml_model.dart';
import 'package:labellab_mobile/model/project.dart';
import 'package:labellab_mobile/model/register_user.dart';
import 'package:labellab_mobile/model/team.dart';
import 'package:labellab_mobile/model/upload_image.dart';
import 'package:labellab_mobile/model/user.dart';
import 'package:labellab_mobile/screen/train/dialogs/dto/model_dto.dart';
import 'package:logger/logger.dart';

class LabelLabAPIImpl extends LabelLabAPI {
  Dio? _dio;
  late FakeServer _fake;

  LabelLabAPIImpl() {
    _dio = Dio();
    _fake = FakeServer();

    _dio!.interceptors.clear();
    _dio!.interceptors.add(RetryOnAuthFailInterceptor(_dio));
    _dio!.interceptors.add(BackendUrlInterceptor(_dio));
  }

  /// BASE_URL - Change according to current labellab server
  static const String API_URL = "api/v1/";
  static String STATIC_CLASSIFICATION_URL = "static/uploads/classifications/";
  static String STATIC_IMAGE_URL = "static/img/";
  static String STATIC_UPLOADS_URL = "static/uploads/";

  // Endpoints
  static const ENDPOINT_LOGIN = "auth/login";
  static const ENDPOINT_REFRESH = "auth/token_refresh";
  static const ENDPOINT_LOGIN_GOOGLE = "auth/google/mobile";
  static const ENDPOINT_LOGIN_GITHUB = "auth/github";
  static const ENDPOINT_REGISTER = "auth/register";
  static const ENDPOINT_UPDATE_PASSWORD = "auth/update-password";

  static const ENDPOINT_USERS_INFO = "users/info";
  static const ENDPOINT_USERS_SEARCH = "users/search";
  static const ENDPOINT_UPLOAD_USER_IMAGE = "users/upload_image";
  static const ENDPOINT_EDIT_INFO = "users/edit/";
  static const ENDPOINT_USERS_LIST = "users/get";

  static const ENDPOINT_PROJECT_GET = "project/get";
  static const ENDPOINT_PROJECT_INFO = "project/project_info";
  static const ENDPOINT_PROJECT_CREATE = "project/create";
  static const ENDPOINT_PROJECT_UPDATE = "project/project_info";
  static const ENDPOINT_PROJECT_DELETE = "project/project_info";
  static const ENDPOINT_PROJECT_ADD_MEMBER = "project/add_project_member";
  static const ENDPOINT_PROJECT_REMOVE_MEMBER = "project/remove_project_member";
  static const ENDPOINT_PROJECT_MEMBER_ROLES = "project/member_roles";
  static const ENDPOINT_PROJECT_LEAVE = "project/leave";
  static const ENDPOINT_PROJECT_MAKE_ADMIN = "project/make_admin";
  static const ENDPOINT_PROJECT_REMOVE_ADMIN = "project/remove_admin";

  static const ENDPOINT_TEAM_CREATE = "project/add_project_member";
  static const ENDPOINT_TEAM_INFO = "team/team_info";
  static const ENDPOINT_TEAM_ADD_MEMBER = "team/add_team_member";
  static const ENDPOINT_TEAM_REMOVE_MEMBER = "team/remove_team_member";
  static const ENDPOINT_TEAM_GET_MESSAGES = "chatroom";

  static const ENDPOINT_ISSUE_GET = "issue/get";
  static const ENDPOINT_ISSUE_CREATE = "issue/create";
  static const ENPOINT_ISSUE_INFO = "issue/issue_info";
  static const ENPOINT_ISSUE_UPDATE = "issue/issue_info";
  static const ENDPOINT_ISSUE_GET_ACTIVITY = "issue";
  static const ENDPOINT_ISSUE_DELETE = "issue/issue_info";
  static const ENDPOINT_ASSIGN_ISSUE = "issue/assign";

  static const ENDPOINT_COMMENT_GET = "comment/get";
  static const ENDPOINT_POST_COMMENT = "comment/create/";
  static const ENDPOINT_UPDATE_COMMENT = "comment/comment_info";

  static const ENDPOINT_PROJECT_GET_ACTIVITY_LOGS = "logs";

  static const ENDPOINT_IMAGE = "image";
  static const ENDPOINT_IMAGES = "images";
  static const ENDPOINT_METADATA = "metadata";

  static const ENDPOINT_GROUP = "group";

  static const ENDPOINT_LABEL = "label";

  static const ENDPOINT_PATH = "path";

  static const ENDPOINT_CLASSIFICAITON_CLASSIFY = "classification/classify";
  static const ENDPOINT_CLASSIFICATION_GET = "classification/get";
  static const ENDPOINT_CLASSIFICATION_ALL = "classification/all";
  static const ENDPOINT_CLASSIFICATION_DELETE = "classification/delete";

  static const ENDPOINT_ML_CLASSIFIER = "mlclassifier";

  @override
  Future<LoginResponse> login(AuthUser user) {
    return _dio!
        .post(API_URL + ENDPOINT_LOGIN, data: user.toMap())
        .then((response) {
      return LoginResponse(response.data);
    }).catchError((err) =>
            throw new Exception(jsonDecode(err.response.toString())['msg']));
  }

  @override
  Future<RefreshResponse> refreshToken(String? refreshToken) {
    Options options = Options(
        headers: {HttpHeaders.authorizationHeader: "Bearer " + refreshToken!});

    return _dio!
        .post(API_URL + ENDPOINT_REFRESH, options: options)
        .then((response) => RefreshResponse(response.data))
        .catchError((err) {
      Logger().e(err);
    });
  }

  @override
  Future<LoginResponse> loginWithGoogle(GoogleUserRequest user) {
    return _dio!
        .post(API_URL + ENDPOINT_LOGIN_GOOGLE, data: user.toMap())
        .then((response) {
      return LoginResponse(response.data);
    }).catchError((err) {
      print(err);
    });
  }

  @override
  Future<LoginResponse> loginWithGithub(String code) {
    return _dio!
        .get(API_URL + ENDPOINT_LOGIN_GITHUB + "/callback?code=" + code)
        .then((response) {
      return LoginResponse(response.data);
    });
  }

  @override
  Future<RegisterResponse> register(RegisterUser user) {
    return _dio!
        .post(API_URL + ENDPOINT_REGISTER, data: user.toMap())
        .then((response) {
      return RegisterResponse(response.data);
    }).catchError((err) =>
            throw new Exception(jsonDecode(err.response.toString())['msg']));
  }

  @override
  Future<ApiResponse> updatePassword(
      String? token, String currentPassword, String newPassword) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .put(
          API_URL + ENDPOINT_UPDATE_PASSWORD,
          options: options,
          data: {
            "current_password": currentPassword,
            "new_password": newPassword,
          },
        )
        .then((response) => ApiResponse(response.data))
        .catchError((err) =>
            throw new Exception(jsonDecode(err.response.toString())['msg']));
  }

  @override
  Future<User> usersInfo(String? token) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_USERS_INFO, options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return User.fromJson(response.data['body'],
            imageEndpoint: STATIC_IMAGE_URL);
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<List<User>> getUsers(String? token) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_USERS_LIST, options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((item) => User.fromJson(item))
            .toList();
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<List<User>> searchUser(String? token, String email) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_USERS_SEARCH + "/$email", options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List)
            .map((user) => User.fromJson(user, imageEndpoint: STATIC_IMAGE_URL))
            .toList();
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<ApiResponse> uploadUserImage(String? token, File image) {
    final imageBytes = image.readAsBytesSync();
    final encodedBytes = base64Encode(imageBytes);
    final data = {"image": "base64," + encodedBytes, "format": "image/jpg"};
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
      // contentType: ContentType.parse("application/x-www-form-urlencoded"),
    );
    return _dio!
        .post(API_URL + ENDPOINT_UPLOAD_USER_IMAGE,
            options: options, data: data)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> editInfo(String? token, String username) {
    final data = {"username": username};
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .put(API_URL + ENDPOINT_EDIT_INFO, options: options, data: data)
        .then((response) {
      return ApiResponse(response.data);
    }).catchError((err) =>
            throw new Exception(jsonDecode(err.response.toString())['msg']));
  }

  @override
  Future<ApiResponse> createProject(String? token, Project project) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .post(API_URL + ENDPOINT_PROJECT_CREATE,
            options: options, data: project.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<Project> getProject(String? token, String? id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_PROJECT_INFO + "/$id", options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        Project project = Project.fromJson(response.data['body'],
            imageEndpoint: STATIC_UPLOADS_URL);
        return project;
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<List<Project>> getProjects(String? token) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_PROJECT_GET, options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((item) => Project.fromJson(item, isDense: true))
            .toList();
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<ApiResponse> updateProject(String? token, Project project) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .put(API_URL + ENDPOINT_PROJECT_UPDATE + "/${project.id}",
            options: options, data: project.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> deleteProject(String? token, String? id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .delete(API_URL + ENDPOINT_PROJECT_DELETE + "/$id", options: options)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> addMember(String? token, String projectId, String email,
      String teamname, String role) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    final data = {
      "member_email": email,
      "team_name": teamname,
      "role": role,
    };
    return _dio!
        .post(API_URL + ENDPOINT_PROJECT_ADD_MEMBER + "/$projectId",
            options: options, data: data)
        .then((response) {
      return ApiResponse(response.data);
    }).catchError((err) =>
            throw new Exception(jsonDecode(err.response.toString())['msg']));
  }

  @override
  Future<ApiResponse> removeMember(
      String? token, String projectId, String? email) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    final data = {
      "member_email": email,
    };
    return _dio!
        .post(API_URL + ENDPOINT_PROJECT_REMOVE_MEMBER + "/$projectId",
            options: options, data: data)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<List<String>> getMemberRoles(String? token, String projectId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(
      API_URL + ENDPOINT_PROJECT_MEMBER_ROLES + "/$projectId",
      options: options,
    )
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List)
            .map((role) => role.toString())
            .toList();
      } else {
        return [];
      }
    });
  }

  @override
  Future<ApiResponse> leaveProject(String? token, String projectId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_PROJECT_LEAVE + "/$projectId", options: options)
        .then((response) {
      return ApiResponse(response.data);
    }).catchError((err) =>
            throw new Exception(jsonDecode(err.response.toString())['msg']));
  }

  @override
  Future<ApiResponse> makeAdmin(
      String? token, String projectId, String memberEmail) {
    Options options =
        Options(headers: {HttpHeaders.authorizationHeader: "Bearer " + token!});
    final data = {"member_email": memberEmail};
    return _dio!
        .post(
      API_URL + ENDPOINT_PROJECT_MAKE_ADMIN + "/$projectId",
      options: options,
      data: data,
    )
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> removeAdmin(
      String? token, String projectId, String memberEmail) {
    Options options =
        Options(headers: {HttpHeaders.authorizationHeader: "Bearer " + token!});
    final data = {"member_email": memberEmail};
    return _dio!
        .post(
      API_URL + ENDPOINT_PROJECT_REMOVE_ADMIN + "/$projectId",
      options: options,
      data: data,
    )
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  // Teams

  @override
  Future<ApiResponse> createTeam(
      String? token, String projectId, Map<String, dynamic> postData) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .post(API_URL + ENDPOINT_TEAM_CREATE + "/$projectId",
            options: options, data: postData)
        .then((response) {
      return ApiResponse(response.data);
    }).catchError((err) =>
            throw new Exception(jsonDecode(err.response.toString())['msg']));
  }

  @override
  Future<ApiResponse> updateTeam(String? token, String projectId, String teamId,
      String teamName, String role) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    final putData = {'teamname': teamName, 'role': role};
    return _dio!
        .put(API_URL + ENDPOINT_TEAM_INFO + "/$projectId/$teamId",
            options: options, data: putData)
        .then((response) {
      return ApiResponse(response.data);
    }).catchError((err) =>
            throw new Exception(jsonDecode(err.response.toString())['msg']));
  }

  @override
  Future<ApiResponse> deleteTeam(
      String? token, String projectId, String teamId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .delete(API_URL + ENDPOINT_TEAM_INFO + "/$projectId/$teamId",
            options: options)
        .then((response) {
      return ApiResponse(response.data);
    }).catchError((err) =>
            throw new Exception(jsonDecode(err.response.toString())['msg']));
  }

  @override
  Future<Team> getTeamDetails(String? token, String projectId, String teamId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_TEAM_INFO + "/$projectId/$teamId",
            options: options)
        .then((response) {
      return Team.fromJson(response.data['body']);
    });
  }

  @override
  Future<ApiResponse> addTeamMember(
      String? token, String projectId, String teamId, String memberEmail) {
    Options options =
        Options(headers: {HttpHeaders.authorizationHeader: "Bearer " + token!});
    final data = {
      "member_email": memberEmail,
    };
    return _dio!
        .post(
      API_URL + ENDPOINT_TEAM_ADD_MEMBER + "/$projectId/$teamId",
      options: options,
      data: data,
    )
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> removeTeamMember(
      String? token, String projectId, String teamId, String memberEmail) {
    Options options =
        Options(headers: {HttpHeaders.authorizationHeader: "Bearer " + token!});
    final data = {
      "member_email": memberEmail,
    };
    return _dio!
        .post(
      API_URL + ENDPOINT_TEAM_REMOVE_MEMBER + "/$projectId/$teamId",
      options: options,
      data: data,
    )
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<List<Message>> getChatroomMessages(String? token, String teamId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get('$API_URL$ENDPOINT_TEAM_GET_MESSAGES/$teamId', options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((item) => Message.fromJson(item))
            .toList();
      } else {
        throw Exception("Request unsuccessful");
      }
    });
  }

  // Logs

  @override
  Future<List<Log>> getProjectActivityLogs(String? token, String projectId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get('$API_URL$ENDPOINT_PROJECT_GET_ACTIVITY_LOGS/$projectId',
            options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['data'] as List<dynamic>)
            .map((item) => Log.fromJSON(item))
            .toList();
      } else {
        throw Exception("Request unsuccessful");
      }
    });
  }

  @override
  Future<List<Log>> getCategorySpecificLogs(
      String? token, String projectId, String category) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(
      '$API_URL$ENDPOINT_PROJECT_GET_ACTIVITY_LOGS/$projectId/category/$category',
      options: options,
    )
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['data'] as List<dynamic>)
            .map((item) => Log.fromJSON(item))
            .toList();
      } else {
        throw Exception("Request unsuccessful");
      }
    });
  }

  @override
  Future<List<Log>> getMemberSpecificLogs(
      String? token, String projectId, String userEmail) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(
      '$API_URL$ENDPOINT_PROJECT_GET_ACTIVITY_LOGS/$projectId/user/$userEmail',
      options: options,
    )
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['data'] as List<dynamic>)
            .map((item) => Log.fromJSON(item))
            .toList();
      } else {
        throw Exception("Request unsuccessful");
      }
    });
  }

  @override
  Future<List<Log>> getEntitySpecificLogs(
      String? token, String projectId, String entityType, String entityId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(
      '$API_URL$ENDPOINT_PROJECT_GET_ACTIVITY_LOGS/$projectId/entity/$entityType/$entityId',
      options: options,
    )
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['data'] as List<dynamic>)
            .map((item) => Log.fromJSON(item))
            .toList();
      } else {
        throw Exception("Request unsuccessful");
      }
    });
  }

  @override
  Future<ApiResponse> uploadImage(
      String? token, String projectId, UploadImage image) async {
    // final imageBytes = image.image.readAsBytesSync();
    // final encodedBytes = base64Encode(imageBytes);

    // final takenAt = (image.metadata != null &&
    //         image.metadata.exif != null &&
    //         image.metadata.exif.dateTime != null)
    //     ? image.metadata.exif.dateTime
    //     : "";
    // final latitude = (image.metadata != null &&
    //         image.metadata.gps != null &&
    //         image.metadata.gps.gpsLatitude != null)
    //     ? image.metadata.gps.gpsLatitude
    //     : "";
    // final longitude = (image.metadata != null &&
    //         image.metadata.gps != null &&
    //         image.metadata.gps.gpsLongitude != null)
    //     ? image.metadata.gps.gpsLongitude
    //     : "";

    // final data = {
    //   "projectId": projectId,
    //   "imageNames": ["Image"],
    //   "images": ["base64," + encodedBytes],
    //   "format": "image/jpg",
    //   "metadata": {
    //     "takenAt": takenAt,
    //     "latitude": latitude,
    //     "longitude": longitude
    //   }
    // };

    FormData data = FormData.fromMap(
        {"images": await MultipartFile.fromFile(image.image!.path)});

    Options options =
        Options(headers: {HttpHeaders.authorizationHeader: "Bearer " + token!});
    return _dio!
        .post(API_URL + ENDPOINT_IMAGE + "/create/$projectId",
            options: options, data: data)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<List<Image>> getImages(String? token, String projectId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_IMAGE + "/get/$projectId", options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((image) => Image.fromJson(image))
            .toList();
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<Image> getImage(String? token, String id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_IMAGE + "/get_image/$id", options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        final image = Image.fromJson(response.data['body'],
            imageEndpoint: STATIC_UPLOADS_URL);
        return image;
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<ApiResponse> updateImage(String? token, String projectId, Image? image,
      List<LabelSelection?> selections) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    final data = {
      "project_id": projectId,
      "labelled": true,
      "labels": selections.map((selection) {
        return selection!.toMap();
      }).toList(),
      "width": image!.width,
      "height": image.height,
    };
    return _dio!
        .put(API_URL + ENDPOINT_IMAGE + "/update/${image.id}",
            options: options, data: data)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> deleteImage(
      String? token, String projectId, String imageId) {
    final data = {
      "images": [imageId]
    };
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .post(API_URL + ENDPOINT_IMAGE + "/delete/$projectId",
            options: options, data: data)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> deleteImages(
      String? token, String projectId, List<String?> imageIds) {
    final data = {"images": imageIds};
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .post(API_URL + ENDPOINT_IMAGE + "/delete/$projectId",
            options: options, data: data)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<List<Location>> getImagesPath(
      String? token, String projectId, List<String?> ids) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );

    return _dio!
        .post(
            API_URL + ENDPOINT_IMAGES + "/" + ENDPOINT_METADATA + "/$projectId",
            options: options)
        .then((response) {
      final bool isSuccess = response.data["success"];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((meta) => Location.fromJson(meta))
            .toList();
      } else {
        throw Exception("Request Failed");
      }
    });
  }

  @override
  Future<ApiResponse> createGroup(
      String? token, String projectId, Group group) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    final data = {
      "group": group.toMap(),
    };
    return _dio!
        .post(API_URL + ENDPOINT_GROUP + "/$projectId/create",
            options: options, data: data)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> addGroupImages(
      String? token, String projectId, String groupId, List<String?> images) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .put(API_URL + ENDPOINT_GROUP + "/$groupId/add-images",
            options: options, data: images)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> updateGroup(String? token, Group group) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .put(API_URL + ENDPOINT_GROUP + "/${group.id}/update",
            options: options, data: group.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<Group> getGroup(String? token, String id) {
    // Options options = Options(
    //   headers: {HttpHeaders.authorizationHeader: "Bearer " + token},
    // );
    // return _dio
    //     .get(API_URL + ENDPOINT_GROUP + "/$id/get", options: options)
    //     .then((response) {
    //   final bool isSuccess = response.data['success'];
    //   if (isSuccess) {
    //     return Group.fromJson(response.data['body']);
    //   } else {
    //     throw Exception("Request unsuccessfull");
    //   }
    // });

    return Future.delayed(Duration(seconds: 1))
        .then((value) => _fake.getGroup!);
  }

  @override
  Future<List<Label>> getLabels(String? token, String projectId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_LABEL + "/get/$projectId", options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((item) => Label.fromJson(item))
            .toList();
      } else {
        return List.from([]);
        // throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<ApiResponse> createLabel(
      String? token, String projectId, Label label) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .post(API_URL + ENDPOINT_LABEL + "/create/$projectId",
            options: options, data: label.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> updateLabel(
      String? token, String projectId, Label label) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .put(API_URL + ENDPOINT_LABEL + "/label_info/${label.id}/$projectId",
            options: options, data: label.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> deleteLabel(
      String? token, String projectId, String? labelId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .delete(API_URL + ENDPOINT_LABEL + "/label_info/$labelId/$projectId",
            options: options)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<Classification> classify(String? token, File image) async {
    Options options =
        Options(headers: {HttpHeaders.authorizationHeader: "Bearer " + token!});

    FormData data =
        FormData.fromMap({"image": await MultipartFile.fromFile(image.path)});

    final response = await _dio!.post(
        API_URL + ENDPOINT_CLASSIFICAITON_CLASSIFY,
        options: options,
        data: data);
    return Classification.fromJson(response.data['body'],
        staticEndpoint: STATIC_CLASSIFICATION_URL);
  }

  @override
  Future<Classification> getClassification(String? token, String id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_CLASSIFICATION_GET + "/$id", options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return Classification.fromJson(response.data['body'],
            staticEndpoint: STATIC_CLASSIFICATION_URL);
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<List<Classification>> getClassifications(String? token) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_CLASSIFICATION_ALL, options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((item) => Classification.fromJson(item,
                staticEndpoint: STATIC_CLASSIFICATION_URL))
            .toList();
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<ApiResponse> deleteClassification(String? token, String? id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .delete(API_URL + ENDPOINT_CLASSIFICATION_DELETE + "/$id",
            options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return ApiResponse(response.data);
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  // @override
  // Future<List<Series>> getResults(String? token) {
  //   return Future.delayed(Duration(seconds: 2))
  //       .then((value) => _fake.getResults!);
  // }

  @override
  Future<List<MlModel>> getModels(String? token, String projectId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_ML_CLASSIFIER + "/all/$projectId",
            options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((model) => MlModel.fromJson(model))
            .toList();
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<List<MlModel>> getTrainedModels(String? token, String projectId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_ML_CLASSIFIER + "/trained/$projectId",
            options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((model) => MlModel.fromJson(model))
            .toList();
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<MlModel> getModel(String? token, String modelId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(API_URL + ENDPOINT_ML_CLASSIFIER + "/$modelId", options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return MlModel.fromJson(response.data["body"]);
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<ApiResponse> createModel(
      String? token, String projectId, MlModel model) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    model.projectId = projectId;
    return _dio!
        .post(API_URL + ENDPOINT_ML_CLASSIFIER,
            options: options, data: model.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> updateModel(
      String? token, String projectId, MlModel model) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    model.projectId = projectId;
    return _dio!
        .put(API_URL + ENDPOINT_ML_CLASSIFIER + '/${model.id}',
            options: options, data: model.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> saveModel(
      String? token, String modelId, MlModel? model, ModelDto modelDto) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    Map<String, dynamic> _data = {
      "id": int.parse(modelId),
      "accuracyGraphUrl": model!.accuracyGraphUrl,
      "batchSize": modelDto.batchSize,
      "epochs": modelDto.epochs,
      "labels": model.labels,
      "layersJsonUrl": model.layersUrl,
      "learningRate": modelDto.learningRate,
      "loss": modelDto.loss,
      "lossGraphUrl": model.lossGraphUrl,
      "metric": MlModelMapper.metricToString(modelDto.metric),
      "name": model.name,
      "optimizer": MlModelMapper.optimizerToString(modelDto.optimizer),
      "preprocessingStepsJsonUrl": model.preprocessingUrl,
      "projectId": model.projectId,
      "savedModelUrl": model.saveModelUrl,
      "source": MlModelMapper.sourceToString(model.source),
      "test": modelDto.test,
      "train": modelDto.train,
      "transferSource": MlModelMapper.learnToString(modelDto.modelToLearn),
      "type": MlModelMapper.typeToString(model.type),
      "validation": modelDto.validation,
      "preprocessingSteps": modelDto.steps.map((step) {
        switch (step.step) {
          case ModelStep.CENTER:
          case ModelStep.STDNORM:
            return {
              "name": MlModelMapper.stepToString(step.step),
              "settings": [
                {"name": "Type", "value": step.extra}
              ]
            };

          case ModelStep.RR:
          case ModelStep.WSR:
          case ModelStep.HSR:
          case ModelStep.SR:
          case ModelStep.ZR:
          case ModelStep.CSR:
            return {
              "name": MlModelMapper.stepToString(step.step),
              "settings": [
                {"name": "Range", "value": step.extra}
              ]
            };

          case ModelStep.RESCALE:
            return {
              "name": MlModelMapper.stepToString(step.step),
              "settings": [
                {"name": "Factor", "value": step.extra}
              ]
            };

          default:
            return {
              "name": MlModelMapper.stepToString(step.step),
              "settings": []
            };
        }
      }).toList(),
      "layers": modelDto.layers.map((layer) {
        switch (layer.layer) {
          case ModelLayer.C2D:
            return {
              "name": MlModelMapper.layerToString(layer.layer),
              "settings": [
                {"name": "Filters", "value": layer.args![0]},
                {"name": "Kernel Size", "value": layer.args![1]},
                {"name": "X Strides", "value": layer.args![2]},
                {"name": "Y Strides", "value": layer.args![3]}
              ]
            };

          case ModelLayer.ACTIVATION:
            return {
              "name": MlModelMapper.layerToString(layer.layer),
              "settings": [
                {"name": "Activation", "value": layer.args!.first}
              ]
            };

          case ModelLayer.MAXPOOL2D:
            return {
              "name": MlModelMapper.layerToString(layer.layer),
              "settings": [
                {"name": "Pool Size X", "value": layer.args!.first},
                {"name": "Pool Size Y", "value": layer.args!.last}
              ]
            };

          case ModelLayer.DENSE:
            return {
              "name": MlModelMapper.layerToString(layer.layer),
              "settings": [
                {"name": "Units", "value": layer.args!.first}
              ]
            };

          case ModelLayer.DROPOUT:
            return {
              "name": MlModelMapper.layerToString(layer.layer),
              "settings": [
                {"name": "Rate", "value": layer.args!.first}
              ]
            };

          default:
            return {
              "name": MlModelMapper.layerToString(layer.layer),
              "settings": []
            };
        }
      }).toList()
    };
    return _dio!
        .put(API_URL + ENDPOINT_ML_CLASSIFIER + "/$modelId",
            options: options, data: _data)
        .then((response) {
      return ApiResponse(response.data);
    }).catchError((error) => ApiResponse.error(error));
  }

  @override
  Future<ApiResponse> trainModel(String? token, String modelId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .post(API_URL + ENDPOINT_ML_CLASSIFIER + "/train/$modelId",
            options: options)
        .then((response) {
      return ApiResponse(response.data);
    }).catchError((error) => ApiResponse.error(error));
  }

  @override
  Future<ApiResponse> deleteModel(String? token, String modelId) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .delete(API_URL + ENDPOINT_ML_CLASSIFIER + "/$modelId",
            options: options)
        .then((response) {
      return ApiResponse(response.data);
    }).catchError((error) => ApiResponse.error(error));
  }

  @override
  Future<List<Issue>> getIssues(String? token, String? project_id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get('$API_URL$ENDPOINT_ISSUE_GET/$project_id', options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body']['items'] as List<dynamic>)
            .map((item) => Issue.fromJson(item, isDense: true))
            .toList();
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<ApiResponse> createIssue(String? token, Issue issue) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .post('$API_URL$ENDPOINT_ISSUE_CREATE/${issue.project_id}',
            options: options, data: issue.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> updateIssue(String? token, Issue issue) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .put('$API_URL$ENPOINT_ISSUE_UPDATE/${issue.project_id}/${issue.id}',
            options: options, data: issue.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<Issue> getIssue(String? token, String? id, String? project_id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get('$API_URL$ENPOINT_ISSUE_INFO/$project_id/$id', options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        Issue issue = Issue.fromJson(
          response.data['body'],
        );
        print(issue.toString());
        return issue;
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<ApiResponse> assignIssue(
      String? token, String projectId, String issueId, String assigneeId) {
    Options options =
        Options(headers: {HttpHeaders.authorizationHeader: "Bearer " + token!});
    final data = {"assignee_id": assigneeId};
    return _dio!
        .put(
      '$API_URL$ENDPOINT_ASSIGN_ISSUE/$projectId/$issueId',
      options: options,
      data: data,
    )
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<List<Issue>> getCategorySpecificIssue(
      String? token, String? projectId, String? category) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get(
      '$API_URL$ENDPOINT_ISSUE_GET_ACTIVITY/$projectId/category/$category',
      options: options,
    )
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['data']['items'] as List<dynamic>)
            .map((item) => Issue.fromJson(item))
            .toList();
      } else {
        throw Exception("Request unsuccessful");
      }
    });
  }

  @override
  Future<ApiResponse> deleteIssue(
      String? token, String? id, String? project_id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .delete('$API_URL$ENDPOINT_ISSUE_DELETE/$project_id/$id',
            options: options)
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<List<Comment>> getComments(String? token, String? issue_id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .get('$API_URL$ENDPOINT_COMMENT_GET/$issue_id', options: options)
        .then((response) {
      final bool isSuccess = response.data['success'];
      if (isSuccess) {
        return (response.data['body'] as List<dynamic>)
            .map((item) => Comment.fromJson(item, isDense: true))
            .toList();
      } else {
        throw Exception("Request unsuccessfull");
      }
    });
  }

  @override
  Future<ApiResponse> postComment(
      String? token, Comment comment, String issue_id) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .post('$API_URL$ENDPOINT_POST_COMMENT/${issue_id}',
            options: options, data: comment.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> updateComment(
      String? token, String? id, Comment comment) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .put('$API_URL$ENDPOINT_UPDATE_COMMENT/${id}/${comment.id}',
            options: options, data: comment.toMap())
        .then((response) {
      return ApiResponse(response.data);
    });
  }

  @override
  Future<ApiResponse> deleteComment(
      String? token, String? id, Comment comment) {
    Options options = Options(
      headers: {HttpHeaders.authorizationHeader: "Bearer " + token!},
    );
    return _dio!
        .delete('$API_URL$ENDPOINT_UPDATE_COMMENT/${id}/${comment.id}',
            options: options)
        .then((response) {
      return ApiResponse(response.data);
    });
  }
}
