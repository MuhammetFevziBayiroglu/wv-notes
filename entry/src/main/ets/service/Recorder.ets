import { media } from '@kit.MediaKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Observed
export default class Recorder {
  private recorder: media.AVRecorder | undefined = undefined;
  private fileName: string = '';
  recorderState: media.AVRecorderState = 'idle';
  fileFd?: number;
  elapsedTime: number = 0;
  private intervalId: number | undefined = undefined;
  onRecordComplete?: (fileName: string) => void;

  get readyToRecord(): boolean {
    return this.recorderState === 'idle' || this.recorderState === 'released';
  }

  get recording(): boolean {
    return this.recorderState === 'started';
  }

  get paused(): boolean {
    return this.recorderState === 'paused';
  }

  async getDecibel(): Promise<number> {
    const amp = await this.recorder?.getAudioCapturerMaxAmplitude()!;
    const db = 20 * Math.log10(amp);
    return db;
  }

  async start(context: Context, quality: string = 'average', maxTimeLimit: number = 0) {
    // initialize recorder
    try {
      this.recorder = await media.createAVRecorder();

      // Callback function for state changes.
      this.recorder.on('stateChange', (state: media.AVRecorderState, reason: media.StateChangeReason) => {
        this.recorderState = state; // track state changes
        if (state === 'started') {
          this.startTimer(maxTimeLimit);
        } else if (state === 'paused' || state === 'stopped' || state === 'released') {
          this.stopTimer();
        }
      });

      // Callback function for errors.
      this.recorder.on('error', (err: BusinessError) => {
        console.error(`avRecorder failed, code is ${err.code}, message is ${err.message}`);
      });

      let bitrate = 100000;
      let sampleRate = 48000;
      if (quality === 'low') {
        bitrate = 32000;
        sampleRate = 16000;
      } else if (quality === 'high') {
        bitrate = 192000;
        sampleRate = 96000;
      }

      const avProfile: media.AVRecorderProfile = {
        audioBitrate: bitrate, // Audio bit rate.
        audioChannels: 2, // Number of audio channels.
        audioCodec: media.CodecMimeType.AUDIO_AAC, // Audio encoding format.
        audioSampleRate: sampleRate, // Audio sampling rate.
        fileFormat: media.ContainerFormatType.CFT_MPEG_4A, // Container format.
      };

      const filePath: string = context.filesDir + `/${Date.now()}.mp3`;
      this.fileName = filePath.split('/').pop() as string;
      const audioFile: fs.File = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      this.fileFd = audioFile.fd; // Obtain the file FD.

      const avConfig: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC, // Audio input source.
        profile: avProfile,
        url: `fd://${this.fileFd.toString()}`, // Obtain the file descriptor of the created audio file
      };

      await this.recorder.prepare(avConfig);
      await this.recorder.start();
      this.elapsedTime = 0;
    } catch (e) {
      console.error('start err:', e.code, e.message);
    } finally {
      fs.closeSync(this.fileFd);
    }
  }

  private startTimer(maxTimeLimit: number) {
    if (this.intervalId === undefined) {
      this.intervalId = setInterval(async () => {
        this.elapsedTime++;
        if (maxTimeLimit > 0 && this.elapsedTime >= maxTimeLimit) {
          const path = await this.stopAndSave();
          if (path && this.onRecordComplete) {
            this.onRecordComplete(path);
          }
        }
      }, 1000);
    }
  }

  private stopTimer() {
    if (this.intervalId !== undefined) {
      clearInterval(this.intervalId);
      this.intervalId = undefined;
    }
  }

  async pause() {
    if (this.recorderState === 'started') {
      await this.recorder?.pause();
    }
  }

  async resume() {
    if (this.recorderState === 'paused') {
      await this.recorder?.resume();
    }
  }

  async stopAndSave() {
    try {
      if (this.recorderState === 'started' || this.recorderState === 'paused') {
        await this.recorder?.stop();
        await this.recorder?.reset();
        await this.recorder?.release();
        this.recorder = undefined;
        this.stopTimer();
      }
      return this.fileName;
    } catch (e) {
      console.error('stop err:', e.code, e.message);
      throw new Error(e.message);
    }
  }
}