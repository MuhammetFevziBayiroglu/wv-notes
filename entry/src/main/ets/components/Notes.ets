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

@Observed
class HeaderParams {
  isSelectionMode: boolean = false;
  selectedCount: number = 0;
  onDelete: () => void = () => {
  };
  onRename: () => void = () => {
  };
  onCancel: () => void = () => {
  };
}

@Builder
function selectionHeaderBuilder(params: HeaderParams) {
  if (params.isSelectionMode) {
    Column({ space: 8 }) {
      Button('delete')
        .onClick(() => {
          params.onDelete();
        })
        .backgroundColor(Color.Transparent)
        .fontColor(Color.Red)
        .fontSize(20)
      if (params.selectedCount === 1) {
        Button('rename')
          .onClick(() => {
            params.onRename();
          })
          .backgroundColor(Color.Transparent)
          .fontColor(Color.Blue)
          .fontSize(20)
      }
      Button('cancel')
        .onClick(() => {
          params.onCancel();
        })
        .backgroundColor(Color.Transparent)
        .fontColor(Color.Gray)
        .fontSize(20)
    }.width('100%').padding({ top: 10, bottom: 10 })
  } else {
    Text('My Notes').fontSize(24).margin({ top: 10, bottom: 10 });
  }
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
  @State isSelectionMode: boolean = false;
  @State selectedRecords: string[] = [];
  headerParams: HeaderParams = new HeaderParams();
  headerContent: ComponentContent<HeaderParams> | null = null;

  aboutToAppear(): void {
    this.headerParams.onDelete = () => {
      this.handleDelete();
    };
    this.headerParams.onRename = () => {
      this.handleRename();
    };
    this.headerParams.onCancel = () => {
      this.handleCancel();
    };
    this.headerContent = new ComponentContent(this.getUIContext(), wrapBuilder(selectionHeaderBuilder), this.headerParams);
  }

  renameController: CustomDialogController | null = new CustomDialogController({
    builder: RenameDialog({
      newName: $renamingName,
      confirm: (newName: string) => {
        if (newName) {
          this.records.renameRecord(this.getUIContext().getHostContext()!, this.selectedRecord, newName);
          this.exitSelectionMode();
        }
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: false
  });

  handleDelete(): void {
    AlertDialog.show({
      title: 'Delete Records',
      message: `Are you sure you want to delete ${this.selectedRecords.length} records?`,
      primaryButton: {
        value: 'Delete',
        fontColor: Color.Red,
        action: () => {
          this.records.deleteRecords(this.getUIContext().getHostContext()!, this.selectedRecords);
          this.exitSelectionMode();
        }
      },
      secondaryButton: {
        value: 'Cancel',
        action: () => {
        }
      }
    });
  }

  handleRename(): void {
    if (this.selectedRecords.length === 1) {
      this.selectedRecord = this.selectedRecords[0];
      this.renamingName = this.selectedRecord;
      this.renameController?.open();
    }
  }

  handleCancel(): void {
    this.exitSelectionMode();
  }

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

  toggleSelection(path: string): void {
    const index = this.selectedRecords.indexOf(path);
    if (index > -1) {
      this.selectedRecords = this.selectedRecords.filter(item => item !== path);
    } else {
      this.selectedRecords = [...this.selectedRecords, path];
    }
    this.updateHeader();
    if (this.selectedRecords.length === 0) {
      this.exitSelectionMode();
    }
  }

  enterSelectionMode(path: string): void {
    this.isSelectionMode = true;
    this.selectedRecords = [path];
    this.updateHeader();
  }

  exitSelectionMode(): void {
    this.isSelectionMode = false;
    this.selectedRecords = [];
    this.updateHeader();
  }

  updateHeader(): void {
    this.headerParams.isSelectionMode = this.isSelectionMode;
    this.headerParams.selectedCount = this.selectedRecords.length;
    this.headerContent?.update(this.headerParams);
  }

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
        header: this.headerContent
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
            .backgroundColor(this.selectedRecords.includes(path) ? Color.Grey : Color.White)
            .foregroundColor(Color.Black)
            .onClick(async () => {
              if (this.isSelectionMode) {
                this.toggleSelection(path);
              } else {
                this.selectedRecord = path;
                this.openSheet = true;
              }
            })
            .gesture(
              LongPressGesture()
                .onAction(() => {
                  if (this.isSelectionMode) {
                    this.toggleSelection(path);
                  } else {
                    this.enterSelectionMode(path);
                  }
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