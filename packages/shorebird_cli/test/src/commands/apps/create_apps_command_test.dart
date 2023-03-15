import 'package:args/args.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shorebird_cli/src/auth/auth.dart';
import 'package:shorebird_cli/src/auth/session.dart';
import 'package:shorebird_cli/src/commands/commands.dart';
import 'package:shorebird_code_push_client/shorebird_code_push_client.dart';
import 'package:test/test.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockAuth extends Mock implements Auth {}

class _MockCodePushClient extends Mock implements CodePushClient {}

class _MockLogger extends Mock implements Logger {}

void main() {
  group('create', () {
    const apiKey = 'test-api-key';
    const productId = 'example';
    const session = Session(apiKey: apiKey);

    late ArgResults argResults;
    late Auth auth;
    late Logger logger;
    late CodePushClient codePushClient;
    late CreateAppCommand command;

    setUp(() {
      argResults = _MockArgResults();
      auth = _MockAuth();
      logger = _MockLogger();
      codePushClient = _MockCodePushClient();
      command = CreateAppCommand(
        auth: auth,
        buildCodePushClient: ({required String apiKey}) => codePushClient,
        logger: logger,
      )..testArgResults = argResults;

      when(() => auth.currentSession).thenReturn(session);
    });

    test('returns correct description', () {
      expect(command.description, equals('Create a new app on Shorebird.'));
    });

    test('returns no user error when not logged in', () async {
      when(() => auth.currentSession).thenReturn(null);
      final result = await command.run();
      expect(result, ExitCode.noUser.code);
    });

    test('prompts for app-id when not provided', () async {
      when(() => logger.prompt(any())).thenReturn(productId);
      await command.run();
      verify(() => logger.prompt(any())).called(1);
      verify(() => codePushClient.createApp(productId: productId)).called(1);
    });

    test('uses provided app-id when provided', () async {
      when(() => argResults['app-id']).thenReturn(productId);
      await command.run();
      verifyNever(() => logger.prompt(any()));
      verify(() => codePushClient.createApp(productId: productId)).called(1);
    });

    test('returns success when app is created', () async {
      when(() => argResults['app-id']).thenReturn(productId);
      when(
        () => codePushClient.createApp(productId: productId),
      ).thenAnswer((_) async {});
      final result = await command.run();
      expect(result, ExitCode.success.code);
    });

    test('returns software error when app creation fails', () async {
      when(() => argResults['app-id']).thenReturn(productId);
      when(
        () => codePushClient.createApp(productId: productId),
      ).thenThrow(Exception());
      final result = await command.run();
      expect(result, ExitCode.software.code);
      verify(
        () => logger.err(any(that: contains('Unable to create app'))),
      ).called(1);
    });
  });
}