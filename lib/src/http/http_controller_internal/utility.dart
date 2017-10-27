import 'dart:mirrors';

import '../http_controller_binding.dart';
import '../request.dart';
import '../response.dart';
import 'bindings.dart';

class InternalControllerException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, String> additionalHeaders;
  final String errorMessage;

  InternalControllerException(this.message, this.statusCode, {Map<String, String> headers, String errorMessage})
      : this.additionalHeaders = headers,
        this.errorMessage = errorMessage;

  Response get response {
    var bodyMap;
    if (errorMessage != null) {
      bodyMap = {"error": errorMessage};
    }
    return new Response(statusCode, additionalHeaders, bodyMap);
  }

  @override
  String toString() => "InternalControllerException: $message";
}


bool requestHasFormData(Request request) {
  var contentType = request.raw.headers.contentType;
  if (contentType != null &&
      contentType.primaryType == "application" &&
      contentType.subType == "x-www-form-urlencoded") {
    return true;
  }

  return false;
}

Map<Symbol, dynamic> toSymbolMap(List<HTTPValueBinding> boundValues) {
  return new Map.fromIterable(boundValues.where((v) => v.value != null),
      key: (HTTPValueBinding v) => v.symbol, value: (HTTPValueBinding v) => v.value);
}


bool isOperation(DeclarationMirror m) {
  return methodBindingFrom(m) != null;
}

HTTPMethod methodBindingFrom(DeclarationMirror m) {
  if (m is! MethodMirror) {
    return null;
  }

  MethodMirror method = m;
  if (!method.isRegularMethod || method.isStatic) {
    return null;
  }

  Bind metadata = method.metadata.firstWhere((im) => im.reflectee is Bind, orElse: () => null)?.reflectee;
  if (metadata == null) {
    return null;
  }

  var binding = metadata.binding;
  if (binding is! HTTPMethod) {
    return null;
  }

  return binding;
}