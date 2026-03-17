import { fileIo as fs } from '@kit.CoreFileKit';
import { media } from '@kit.MediaKit';

@Observed
export class RecordItem {
  name: string;
  duration: string = '0:00';
  size: string = '0 KB';

  constructor(name: string) {
    this.name = name;
  }
}

@Observed
export default class Records {
  items: RecordItem[] = [];

  constructor(context: Context) {
    this.items = this._getAll(context);
  }

  private _getAll(context: Context): RecordItem[] {
    try {
      const filesDir = context.filesDir;
      const files: string[] = fs.listFileSync(filesDir);
      files.sort((a, b) => a.localeCompare(b));
      return files.map(f => new RecordItem(f));
    } catch (_) {
      console.error(_);
      return [];
    }
  }

  async fetchDurations(context: Context) {
    for (const item of this.items) {
      item.duration = await this._getDuration(context, item.name);
      item.size = this._getSize(context, item.name);
    }
    this.items = [...this.items];
  }

  private _formatSize(bytes: number): string {
    if (bytes < 1024) {
      return bytes + ' B';
    } else if (bytes < 1024 * 1024) {
      return (bytes / 1024).toFixed(1) + ' KB';
    } else {
      return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
    }
  }

  private _getSize(context: Context, fileName: string): string {
    try {
      const filePath = context.filesDir + '/' + fileName;
      const stat = fs.statSync(filePath);
      return this._formatSize(stat.size);
    } catch (e) {
      console.error('getSize err:', e);
      return '0 KB';
    }
  }

  private async _getDuration(context: Context, fileName: string): Promise<string> {
    let avMetadataExtractor: media.AVMetadataExtractor | undefined = undefined;
    let file: fs.File | undefined = undefined;
    try {
      avMetadataExtractor = await media.createAVMetadataExtractor();
      const filePath = context.filesDir + '/' + fileName;
      file = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
      avMetadataExtractor.fdSrc = { fd: file.fd };

      const metadata = await avMetadataExtractor.fetchMetadata();
      const durationMs = Number.parseInt(metadata.duration ?? '0');
      const totalSeconds = Math.floor(durationMs / 1000);
      const minutes = Math.floor(totalSeconds / 60);
      const seconds = totalSeconds % 60;
      // Ensure seconds are always 2 digits
      return `${minutes}:${seconds.toString().padStart(2, '0')}`;
    } catch (e) {
      console.error('getDuration err:', e);
      return '0:00';
    } finally {
      if (file) {
        fs.closeSync(file.fd);
      }
      await avMetadataExtractor?.release();
    }
  }

  addNew(fileName: string) {
    const copy = Array.from(this.items);
    copy.push(new RecordItem(fileName));
    this.items = copy;
  }

  deleteRecord(context: Context, fileName: string) {
    try {
      const filePath = context.filesDir + '/' + fileName;
      fs.unlinkSync(filePath);
      this.items = this.items.filter(item => item.name !== fileName);
    } catch (e) {
      console.error('deleteRecord err:', e);
    }
  }

  deleteRecords(context: Context, fileNames: string[]) {
    const successfullyDeleted: string[] = [];
    fileNames.forEach(fileName => {
      try {
        const filePath = context.filesDir + '/' + fileName;
        fs.unlinkSync(filePath);
        successfullyDeleted.push(fileName);
      } catch (e) {
        console.error('deleteRecord err:', e);
      }
    });
    if (successfullyDeleted.length > 0) {
      const deletedSet = new Set(successfullyDeleted);
      this.items = this.items.filter(item => !deletedSet.has(item.name));
    }
  }

  renameRecord(context: Context, oldName: string, newName: string) {
    try {
      const parts = oldName.split('.');
      const ext = parts.length > 1 ? parts.pop() : '';
      const finalNewName = (ext && !newName.endsWith('.' + ext)) ? `${newName}.${ext}` : newName;

      const oldPath = context.filesDir + '/' + oldName;
      const newPath = context.filesDir + '/' + finalNewName;
      fs.renameSync(oldPath, newPath);
      this.items = this.items.map(item => {
        if (item.name === oldName) {
          item.name = finalNewName;
        }
        return item;
      });
      this.items = [...this.items];
    } catch (e) {
      console.error('renameRecord err:', e);
    }
  }
}
