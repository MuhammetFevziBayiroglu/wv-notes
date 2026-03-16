import Player from '../service/Player';
import Records from '../service/Records';
import { media } from '@kit.MediaKit';

@Builder
export default function playerBuilder(fileName: string, records: Records) {
  PlayerPage({
    fileName: fileName,
    records: records
  });
}

@Component
struct PlayerPage {
  @Require fileName: string;
  @Require records: Records;
  private filesDir = this.getUIContext().getHostContext()?.filesDir!;
  @State player: Player = new Player();
  @State currentFileName: string = '';

  async aboutToDisappear() {
    await this.player.stop();
  }

  aboutToAppear(): void {
    this.currentFileName = this.fileName;
    this.player.onCompleted = () => {
      this.playNext();
    }
  }

  playNext() {
    const currentIndex = this.records.items.findIndex(item => item.name === this.currentFileName);
    if (currentIndex !== -1 && currentIndex < this.records.items.length - 1) {
      const nextRecord = this.records.items[currentIndex + 1];
      this.currentFileName = nextRecord.name;
      this.player.stop().then(() => {
        this.player.start(`${this.filesDir}/${this.currentFileName}`);
      });
    }
  }

  build() {
    Stack() {
      PlayerControls({
        player: this.player,
        currentFileName: this.currentFileName,
        onPlayPause: () => {
          if (!this.player.playing) {
            this.player.start(`${this.filesDir}/${this.currentFileName}`);
          } else {
            this.player.pause();
          }
        }
      })
    }
    .size({ width: '100%', height: '100%' })
    .onAppear(() => {
      this.player.start(`${this.filesDir}/${this.currentFileName}`);
    });
  }
}

@Component
struct PlayerControls {
  @ObjectLink player: Player;
  @Prop currentFileName: string;
  onPlayPause: () => void = () => {};

  formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }

  build() {
    Column({ space: 4 }) {
      Text(this.currentFileName)
        .fontSize(12)
        .fontColor(Color.White)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('70%')
        .textAlign(TextAlign.Center)

      Slider({
        value: this.player.currentTime,
        min: 0,
        max: this.player.duration,
        step: 1
      })
        .width('60%')
        .height(16)
        .onChange((value: number, mode: SliderChangeMode) => {
          if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
            this.player.seek(value);
          }
        })

      Row() {
        Text(this.formatTime(this.player.currentTime))
          .fontSize(10)
          .fontColor(Color.White)
        Blank()
        Text(`-${this.formatTime(this.player.duration - this.player.currentTime)}`)
          .fontSize(10)
          .fontColor(Color.White)
      }.width('60%')

      Row({ space: 10 }) {
        Button() {
          SymbolGlyph($r('sys.symbol.gobackward_10'))
            .fontColor([Color.White])
            .fontSize(20);
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.player.seek(Math.max(0, this.player.currentTime - 10000));
        })

        Button() {
          if (this.player.playing) {
            SymbolGlyph($r('sys.symbol.pause'))
              .fontColor([Color.White])
              .fontSize(24);
          } else {
            SymbolGlyph($r('sys.symbol.play_fill'))
              .fontColor([Color.White])
              .fontSize(24);
          }
        }
        .type(ButtonType.Circle)
        .backgroundColor(Color.Transparent)
        .size({ width: 44, height: 44 })
        .border({ color: Color.White, width: 2 })
        .onClick(() => {
          this.onPlayPause();
        });

        Button() {
          SymbolGlyph($r('sys.symbol.goforward_10'))
            .fontColor([Color.White])
            .fontSize(20);
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.player.seek(Math.min(this.player.duration, this.player.currentTime + 10000));
        })
      }

      Select([
        { value: '0.5x' },
        { value: '1.0x' },
        { value: '2.0x' }
      ])
        .selected(1)
        .value('1.0x')
        .font({ size: 10 })
        .fontColor(Color.White)
        .selectedOptionFont({ size: 10 })
        .optionFont({ size: 10 })
        .backgroundColor(Color.Transparent)
        .height(30)
        .onSelect((index: number) => {
          let speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
          if (index === 0) speed = media.PlaybackSpeed.SPEED_FORWARD_0_75_X;
          if (index === 2) speed = media.PlaybackSpeed.SPEED_FORWARD_2_00_X;
          this.player.setSpeed(speed);
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
