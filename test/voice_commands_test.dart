import 'package:flutter_test/flutter_test.dart';
import 'package:ozouma/cooking/voice_commands.dart';

void main() {
  test('English commands', () {
    expect(VoiceCommands.parse('next'), CookCommand.next);
    expect(VoiceCommands.parse('Next step please'), CookCommand.next);
    expect(VoiceCommands.parse('go back'), CookCommand.back);
    expect(VoiceCommands.parse('repeat that'), CookCommand.repeat);
    expect(VoiceCommands.parse('pause'), CookCommand.pause);
    expect(VoiceCommands.parse('continue'), CookCommand.resume);
    expect(VoiceCommands.parse('ingredients'), CookCommand.ingredients);
    expect(VoiceCommands.parse('how long is left'), CookCommand.howLong);
    expect(VoiceCommands.parse('stop'), CookCommand.stopAlarm);
  });

  test('Egyptian Arabic commands', () {
    expect(VoiceCommands.parse('اللي بعده'), CookCommand.next);
    expect(VoiceCommands.parse('ارجع'), CookCommand.back);
    expect(VoiceCommands.parse('اللي قبله'), CookCommand.back);
    expect(VoiceCommands.parse('تاني'), CookCommand.repeat);
    expect(VoiceCommands.parse('استنى'), CookCommand.pause);
    expect(VoiceCommands.parse('كمّل'), CookCommand.resume);
    expect(VoiceCommands.parse('المكونات'), CookCommand.ingredients);
    expect(VoiceCommands.parse('فاضل قد إيه'), CookCommand.howLong);
    expect(VoiceCommands.parse('خلاص'), CookCommand.stopAlarm);
  });

  test('longer phrases win over the words inside them', () {
    expect(VoiceCommands.parse('okay next'), CookCommand.next);
    expect(VoiceCommands.parse('الخطوة اللي بعدها'), CookCommand.next);
  });

  test('unrelated speech is ignored', () {
    expect(VoiceCommands.parse(''), isNull);
    expect(VoiceCommands.parse('the onions smell great'), isNull);
    expect(VoiceCommands.parse('الأكل ريحته حلوة'), isNull);
  });
}
