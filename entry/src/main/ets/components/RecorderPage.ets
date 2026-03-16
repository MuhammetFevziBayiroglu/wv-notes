import Recorder from '../service/Recorder';
import Records from '../service/Records';
import CircularWaveVM from '../viewmodel/CircularWaveVM';
import { CircularWaveAnimation } from './CircularWaveAnimation';

@Component
export default struct RecorderPage {
  @ObjectLink recorder: Recorder; // get recorder from parent
  @ObjectLink records: Records;
  @State waveWm: CircularWaveVM = new CircularWaveVM()
  @State quality: string = 'average';
  @State maxTimeLimit: number = 0;
  private intervalId: number | undefined = undefined

  aboutToAppear(): void {
    this.recorder.onRecordComplete = (path: string) => {
      this.records.addNew(path);
      this.clearVisualization();
    };
  }

  clearVisualization() {
    if (this.intervalId !== undefined) {
      clearInterval(this.intervalId);
      this.intervalId = undefined;
    }
    this.waveWm.clear();
  }

  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  build() {
    Stack() {
      CircularWaveAnimation({
        waveVm: this.waveWm
      })

      Column({ space: 10 }) {
        if (this.recorder.recording || this.recorder.paused) {
          Text(this.formatTime(this.recorder.elapsedTime))
            .fontSize(24)
            .fontColor(Color.White)
        } else {
          Column({ space: 5 }) {
            Row({ space: 10 }) {
              Text('Quality:').fontColor(Color.White).fontSize(14)
              Select([
                { value: 'Low' },
                { value: 'Average' },
                { value: 'High' }
              ])
                .selected(1)
                .value('Average')
                .font({ size: 14 })
                .fontColor(Color.White)
                .onSelect((index: number) => {
                  const qualities = ['low', 'average', 'high'];
                  this.quality = qualities[index];
                })
            }

            Row({ space: 10 }) {
              Text('Max Time (s):').fontColor(Color.White).fontSize(14)
              TextInput({ placeholder: '0 for no limit' })
                .type(InputType.Number)
                .width(100)
                .height(35)
                .fontSize(14)
                .onChange((value: string) => {
                  this.maxTimeLimit = Number.parseInt(value) || 0;
                })
            }
          }.margin({ bottom: 20 })
        }

        Row({ space: 20 }) {
          if (this.recorder.recording || this.recorder.paused) {
            Button() {
              SymbolGlyph(this.recorder.paused ? $r('sys.symbol.play_fill') : $r('sys.symbol.pause'))
                .fontColor([Color.White])
                .fontSize(24);
            }
            .type(ButtonType.Circle)
            .backgroundColor(Color.Transparent)
            .size({ width: 50, height: 50 })
            .border({ color: Color.White, width: 3 })
            .onClick(async () => {
              if (this.recorder.recording) {
                await this.recorder.pause();
              } else {
                await this.recorder.resume();
              }
            })
          }

          Button() {
            Stack() {
              if (this.recorder.recording || this.recorder.paused) {
                Rect({ width: '35%', height: '35%' })
                  .fill(Color.Red)
              } else {
                Circle({ width: '90%', height: '90%' })
                  .fill(Color.Red)
                  .transition(
                    TransitionEffect.asymmetric(
                      TransitionEffect.scale({ x: 0.5, y: 0.5 }).animation({ duration: 200 }),
                      TransitionEffect.scale({ x: 0.35, y: 0.35 }).animation({ duration: 200 }),
                    )
                  )
              }
            }
            .size({ width: '100%', height: '100%' })
            .align(Alignment.Center)
          }
          .type(ButtonType.Circle)
          .backgroundColor(Color.Transparent)
          .size({ width: '50%', height: '50%' })
          .border({ color: Color.White, width: 5 })
          .onClick(async () => {
            if (this.recorder.readyToRecord) { // start the recording
              await this.recorder.start(this.getUIContext().getHostContext()!, this.quality, this.maxTimeLimit)
              this.intervalId = setInterval(async () => {
                if (this.recorder.recording) {
                  const db = await this.recorder.getDecibel()
                  this.waveWm.addData(db)
                }
              }, 50)
            } else if (this.recorder.recording || this.recorder.paused) { // stop and save
              const path = await this.recorder.stopAndSave()
              if (path) {
                this.records.addNew(path)
                this.clearVisualization()
              }
            }
          })
        }
      }.width('100%').alignItems(HorizontalAlign.Center)
    }
  }
}