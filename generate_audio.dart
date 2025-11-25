import 'dart:io';
import 'dart:typed_data';

void main() {
  final file = File('assets/alarm.wav');

  // 1초 길이의 440Hz Square Wave (Beep) 생성
  final int sampleRate = 44100;
  final int durationSeconds = 1;
  final int numSamples = sampleRate * durationSeconds;
  final int numChannels = 1;
  final int byteRate = sampleRate * numChannels * 2; // 16-bit
  final int blockAlign = numChannels * 2;

  final int dataSize = numSamples * numChannels * 2;
  final int fileSize = 36 + dataSize;

  final buffer = BytesBuilder();

  // RIFF header
  buffer.add('RIFF'.codeUnits);
  buffer.add(_int32ToBytes(fileSize));
  buffer.add('WAVE'.codeUnits);

  // fmt chunk
  buffer.add('fmt '.codeUnits);
  buffer.add(_int32ToBytes(16)); // chunk size
  buffer.add(_int16ToBytes(1)); // audio format (PCM)
  buffer.add(_int16ToBytes(numChannels));
  buffer.add(_int32ToBytes(sampleRate));
  buffer.add(_int32ToBytes(byteRate));
  buffer.add(_int16ToBytes(blockAlign));
  buffer.add(_int16ToBytes(16)); // bits per sample

  // data chunk
  buffer.add('data'.codeUnits);
  buffer.add(_int32ToBytes(dataSize));

  // Generate square wave data
  for (int i = 0; i < numSamples; i++) {
    final int period = sampleRate ~/ 440;
    final int sampleValue = (i % period) < (period / 2) ? 10000 : -10000;
    buffer.add(_int16ToBytes(sampleValue));
  }

  file.writeAsBytesSync(buffer.toBytes());
  print('Generated assets/alarm.wav');
}

List<int> _int32ToBytes(int value) {
  return Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);
}

List<int> _int16ToBytes(int value) {
  return Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);
}
