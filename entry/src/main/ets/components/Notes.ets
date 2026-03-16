import Records from '../service/Records';
import {
  ArcList,
  ArcListItem,
  ArcListAttribute,
  ArcListItemAttribute,
  ComponentContent,
  LengthMetrics
} from '@kit.ArkUI';
import playerBuilder from './PlayerPage';

@Builder
function titleBuilder() {
  Text('My Notes').fontSize(24);
}

@CustomDialog
struct RenameDialog {
  controller: CustomDialogController;
  @Link newName: string;
  confirm: (newName: string) => void = () => {
  };

  build() {
    Column() {
      Text('Rename Record').fontSize(20).margin({ top: 10, bottom: 10 })
      TextInput({ placeholder: 'Enter new name', text: this.newName })
        .onChange((value: string) => {
          this.newName = value;
        })
        .width('90%')
        .margin({ bottom: 20 })
      Row() {
        Button('Cancel')
          .onClick(() => {
            this.controller.close();
          })
          .backgroundColor(Color.Transparent)
          .fontColor(Color.Blue)
        Button('OK')
          .onClick(() => {
            this.confirm(this.newName);
            this.controller.close();
          })
          .backgroundColor(Color.Transparent)
          .fontColor(Color.Blue)
      }.width('100%').justifyContent(FlexAlign.SpaceAround)
    }.padding(20)
  }
}

@CustomDialog
struct OptionsDialog {
  controller: CustomDialogController;
  rename: () => void = () => {
  };
  delete: () => void = () => {
  };

  build() {
    Column() {
      Button() {
        Text('Rename').fontColor(Color.Blue).fontSize(16)
      }
      .width('100%')
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.rename();
        this.controller.close();
      })

      Divider()

      Button() {
        Text('Delete').fontColor(Color.Red).fontSize(16)
      }
      .width('100%')
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.delete();
        this.controller.close();
      })

      Divider()

      Button() {
        Text('Cancel').fontColor(Color.Gray).fontSize(16)
      }
      .width('100%')
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.controller.close();
      })
    }.padding(10).width('100%')
  }
}

@Component
export default struct Notes {
  @ObjectLink records: Records;
  @State openSheet: boolean = false;
  selectedRecord: string = '';
  @State renamingName: string = '';
  renameController: CustomDialogController | null = new CustomDialogController({
    builder: RenameDialog({
      newName: $renamingName,
      confirm: (newName: string) => {
        if (newName) {
          this.records.renameRecord(this.getUIContext().getHostContext()!, this.selectedRecord, newName);
        }
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: false
  });
  optionsController: CustomDialogController | null = new CustomDialogController({
    builder: OptionsDialog({
      rename: () => {
        this.renamingName = this.selectedRecord;
        this.renameController?.open();
      },
      delete: () => {
        AlertDialog.show({
          title: 'Delete Record',
          message: 'Are you sure you want to delete this record?',
          primaryButton: {
            value: 'Delete',
            fontColor: Color.Red,
            action: () => {
              this.records.deleteRecord(this.getUIContext().getHostContext()!, this.selectedRecord);
            }
          },
          secondaryButton: {
            value: 'Cancel',
            action: () => {
            }
          }
        });
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: false
  });

  formatPath(path: string): string {
    const timestamp = Number.parseInt(path.split('.')[0]);
    if (!isNaN(timestamp) && timestamp.toString().length >= 10) {
      return new Date(timestamp).toLocaleString();
    }
    return path;
  }

  build() {
    Stack() {
      ArcList({
        header: new ComponentContent(this.getUIContext(), wrapBuilder(titleBuilder))
      }) {
        ForEach(this.records.fileNames, (path: string) => {
          ArcListItem() {
            Button() {
              Row() {
                Text(this.formatPath(path));
                Blank().layoutWeight(1);
                SymbolGlyph($r('sys.symbol.arrow_right'));
              }.padding({ left: 16, right: 16 });
            }
            .width('100%')
            .height(40)
            .backgroundColor(Color.White)
            .foregroundColor(Color.Black)
            .onClick(async () => {
              this.selectedRecord = path;
              this.openSheet = true;
            })
            .gesture(
              LongPressGesture()
                .onAction(() => {
                  this.selectedRecord = path;
                  this.optionsController?.open();
                })
            );
          }.width('calc(100% - 32vp)');
        }, (item: string) => item);
      }.space(LengthMetrics.vp(8));
    }
    .bindSheet($$this.openSheet, playerBuilder(this.selectedRecord), {
      height: SheetSize.MEDIUM,
      backgroundColor: Color.Black
    });
  }
}