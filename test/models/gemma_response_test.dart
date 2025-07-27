import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/gemma_response.dart';

void main() {
  group('GemmaResponse', () {
    group('TextResponse', () {
      test('should create TextResponse with required parameters', () {
        const response = TextResponse('Hello world');

        expect(response.token, equals('Hello world'));
        expect(response.isComplete, isFalse);
        expect(response.responseType, equals('text'));
      });

      test('should create TextResponse with isComplete flag', () {
        const response = TextResponse('Final token', isComplete: true);

        expect(response.token, equals('Final token'));
        expect(response.isComplete, isTrue);
        expect(response.responseType, equals('text'));
      });

      test('should serialize and deserialize correctly', () {
        const original = TextResponse('Test token', isComplete: true);

        final json = original.toJson();
        final deserialized = TextResponse.fromJson(json);

        expect(deserialized.token, equals(original.token));
        expect(deserialized.isComplete, equals(original.isComplete));
        expect(deserialized.responseType, equals(original.responseType));
      });

      test('should handle equality correctly', () {
        const response1 = TextResponse('Same token', isComplete: true);
        const response2 = TextResponse('Same token', isComplete: true);
        const response3 = TextResponse('Different token', isComplete: true);
        const response4 = TextResponse('Same token', isComplete: false);

        expect(response1, equals(response2));
        expect(response1, isNot(equals(response3)));
        expect(response1, isNot(equals(response4)));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('should handle empty token', () {
        const response = TextResponse('');

        expect(response.token, equals(''));
        expect(response.isComplete, isFalse);

        final json = response.toJson();
        final deserialized = TextResponse.fromJson(json);

        expect(deserialized.token, equals(''));
      });

      test('should default isComplete to false when not specified in JSON', () {
        final json = {
          'type': 'text',
          'token': 'Test token',
        };

        final response = TextResponse.fromJson(json);

        expect(response.isComplete, isFalse);
      });
    });

    group('FunctionCallResponse', () {
      test('should create FunctionCallResponse with required parameters', () {
        final args = {'param1': 'value1', 'param2': 42};
        final response = FunctionCallResponse('test_function', args);

        expect(response.name, equals('test_function'));
        expect(response.args, equals(args));
        expect(response.callId, isNull);
        expect(response.responseType, equals('function_call'));
      });

      test('should create FunctionCallResponse with callId', () {
        final args = {'param': 'value'};
        final response = FunctionCallResponse('test_function', args, callId: 'call-123');

        expect(response.name, equals('test_function'));
        expect(response.args, equals(args));
        expect(response.callId, equals('call-123'));
        expect(response.responseType, equals('function_call'));
      });

      test('should serialize and deserialize correctly', () {
        final args = {'param1': 'value1', 'param2': 42};
        final original = FunctionCallResponse('serialize_test', args, callId: 'call-456');

        final json = original.toJson();
        final deserialized = FunctionCallResponse.fromJson(json);

        expect(deserialized.name, equals(original.name));
        expect(deserialized.args, equals(original.args));
        expect(deserialized.callId, equals(original.callId));
        expect(deserialized.responseType, equals(original.responseType));
      });

      test('should handle equality correctly', () {
        final args1 = {'param': 'value'};
        final args2 = {'param': 'value'};
        final args3 = {'param': 'different'};

        final response1 = FunctionCallResponse('same_function', args1, callId: 'call-1');
        final response2 = FunctionCallResponse('same_function', args2, callId: 'call-1');
        final response3 = FunctionCallResponse('same_function', args3, callId: 'call-1');
        final response4 = FunctionCallResponse('different_function', args1, callId: 'call-1');

        expect(response1, equals(response2));
        expect(response1, isNot(equals(response3)));
        expect(response1, isNot(equals(response4)));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('should handle null callId correctly', () {
        final args = {'param': 'value'};
        final response = FunctionCallResponse('test_function', args);

        expect(response.callId, isNull);

        final json = response.toJson();
        final deserialized = FunctionCallResponse.fromJson(json);

        expect(deserialized.callId, isNull);
      });

      test('should handle complex nested arguments', () {
        final complexArgs = {
          'nested': {
            'level1': {
              'level2': ['item1', 'item2'],
              'number': 42,
            },
          },
          'list': [1, 2, 3],
          'boolean': true,
        };

        final response = FunctionCallResponse('complex_function', complexArgs);

        final json = response.toJson();
        final deserialized = FunctionCallResponse.fromJson(json);

        expect(deserialized.args, equals(complexArgs));
      });

      test('should handle empty arguments', () {
        final emptyArgs = <String, dynamic>{};
        final response = FunctionCallResponse('no_args_function', emptyArgs);

        expect(response.args, isEmpty);

        final json = response.toJson();
        final deserialized = FunctionCallResponse.fromJson(json);

        expect(deserialized.args, isEmpty);
      });
    });

    group('ErrorResponse', () {
      test('should create ErrorResponse with required parameters', () {
        const response = ErrorResponse('Something went wrong');

        expect(response.error, equals('Something went wrong'));
        expect(response.errorCode, isNull);
        expect(response.details, isNull);
        expect(response.responseType, equals('error'));
      });

      test('should create ErrorResponse with errorCode and details', () {
        final details = {'line': 42, 'column': 10};
        const response = ErrorResponse(
          'Syntax error',
          errorCode: 'SYNTAX_ERROR',
          details: {'line': 42, 'column': 10},
        );

        expect(response.error, equals('Syntax error'));
        expect(response.errorCode, equals('SYNTAX_ERROR'));
        expect(response.details, equals(details));
        expect(response.responseType, equals('error'));
      });

      test('should serialize and deserialize correctly', () {
        final details = {'context': 'test', 'severity': 'high'};
        const original = ErrorResponse(
          'Test error',
          errorCode: 'TEST_ERROR',
          details: {'context': 'test', 'severity': 'high'},
        );

        final json = original.toJson();
        final deserialized = ErrorResponse.fromJson(json);

        expect(deserialized.error, equals(original.error));
        expect(deserialized.errorCode, equals(original.errorCode));
        expect(deserialized.details, equals(original.details));
        expect(deserialized.responseType, equals(original.responseType));
      });

      test('should handle equality correctly', () {
        final details1 = {'key': 'value'};
        final details2 = {'key': 'value'};
        final details3 = {'key': 'different'};

        const response1 = ErrorResponse('Same error', errorCode: 'CODE', details: {'key': 'value'});
        const response2 = ErrorResponse('Same error', errorCode: 'CODE', details: {'key': 'value'});
        const response3 = ErrorResponse('Same error', errorCode: 'CODE', details: {'key': 'different'});
        const response4 = ErrorResponse('Different error', errorCode: 'CODE', details: {'key': 'value'});

        expect(response1, equals(response2));
        expect(response1, isNot(equals(response3)));
        expect(response1, isNot(equals(response4)));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('should handle null errorCode and details correctly', () {
        const response = ErrorResponse('Simple error');

        expect(response.errorCode, isNull);
        expect(response.details, isNull);

        final json = response.toJson();
        final deserialized = ErrorResponse.fromJson(json);

        expect(deserialized.errorCode, isNull);
        expect(deserialized.details, isNull);
      });

      test('should handle empty error message', () {
        const response = ErrorResponse('');

        expect(response.error, equals(''));

        final json = response.toJson();
        final deserialized = ErrorResponse.fromJson(json);

        expect(deserialized.error, equals(''));
      });

      test('should handle complex details', () {
        final complexDetails = {
          'stackTrace': ['line1', 'line2', 'line3'],
          'context': {
            'function': 'testFunction',
            'parameters': {'param1': 'value1'},
          },
          'timestamp': '2023-01-01T00:00:00Z',
        };

        final response = ErrorResponse('Complex error', details: complexDetails);

        final json = response.toJson();
        final deserialized = ErrorResponse.fromJson(json);

        expect(deserialized.details, equals(complexDetails));
      });
    });

    group('GemmaResponse.fromJson', () {
      test('should create correct response type from JSON', () {
        final textJson = {
          'type': 'text',
          'token': 'Hello',
          'isComplete': false,
        };

        final functionJson = {
          'type': 'function_call',
          'name': 'test_function',
          'args': {'param': 'value'},
          'callId': 'call-1',
        };

        final errorJson = {
          'type': 'error',
          'error': 'Test error',
          'errorCode': 'TEST_ERROR',
          'details': {'context': 'test'},
        };

        final textResponse = GemmaResponse.fromJson(textJson);
        final functionResponse = GemmaResponse.fromJson(functionJson);
        final errorResponse = GemmaResponse.fromJson(errorJson);

        expect(textResponse, isA<TextResponse>());
        expect(functionResponse, isA<FunctionCallResponse>());
        expect(errorResponse, isA<ErrorResponse>());
      });

      test('should throw ArgumentError for unknown response type', () {
        final invalidJson = {
          'type': 'unknown',
          'data': 'Invalid response',
        };

        expect(
          () => GemmaResponse.fromJson(invalidJson),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('StreamingResponseHandler', () {
      late StreamingResponseHandler handler;

      setUp(() {
        handler = StreamingResponseHandler();
      });

      test('should handle adding tokens correctly', () {
        const token1 = TextResponse('Hello ');
        const token2 = TextResponse('world');
        const token3 = TextResponse('!', isComplete: true);

        handler.addToken(token1);
        handler.addToken(token2);
        handler.addToken(token3);

        expect(handler.completeText, equals('Hello world!'));
        expect(handler.tokens.length, equals(3));
        expect(handler.isComplete, isTrue);
      });

      test('should handle empty tokens', () {
        expect(handler.completeText, equals(''));
        expect(handler.tokens, isEmpty);
        expect(handler.isComplete, isFalse);
      });

      test('should handle clearing correctly', () {
        const token = TextResponse('Test token');
        handler.addToken(token);

        expect(handler.completeText, equals('Test token'));
        expect(handler.tokens.length, equals(1));

        handler.clear();

        expect(handler.completeText, equals(''));
        expect(handler.tokens, isEmpty);
        expect(handler.isComplete, isFalse);
      });

      test('should create complete response correctly', () {
        const token1 = TextResponse('Hello ');
        const token2 = TextResponse('world!');

        handler.addToken(token1);
        handler.addToken(token2);

        final completeResponse = handler.toCompleteResponse();

        expect(completeResponse.token, equals('Hello world!'));
        expect(completeResponse.isComplete, isTrue);
      });

      test('should handle isComplete flag correctly', () {
        const incompleteToken = TextResponse('Partial');
        const completeToken = TextResponse(' complete', isComplete: true);

        handler.addToken(incompleteToken);
        expect(handler.isComplete, isFalse);

        handler.addToken(completeToken);
        expect(handler.isComplete, isTrue);
      });

      test('should return unmodifiable list of tokens', () {
        const token = TextResponse('Test');
        handler.addToken(token);

        final tokens = handler.tokens;
        expect(() => tokens.add(const TextResponse('Another')), throwsUnsupportedError);
      });

      test('should handle multiple complete tokens', () {
        const token1 = TextResponse('First', isComplete: true);
        const token2 = TextResponse(' Second', isComplete: false);
        const token3 = TextResponse(' Third', isComplete: true);

        handler.addToken(token1);
        expect(handler.isComplete, isTrue);

        handler.addToken(token2);
        expect(handler.isComplete, isFalse);

        handler.addToken(token3);
        expect(handler.isComplete, isTrue);
        expect(handler.completeText, equals('First Second Third'));
      });
    });
  });
}