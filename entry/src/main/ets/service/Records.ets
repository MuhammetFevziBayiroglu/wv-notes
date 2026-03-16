import { fileIo as fs } from '@kit.CoreFileKit';

@Observed
export default class Records {
  fileNames: string[] = [];

  constructor(context: Context) {
    this.fileNames = this._getAll(context);
  }

  private _getAll(context: Context): string[] {
    try {
      const filesDir = context.filesDir;
      const files: string[] = fs.listFileSync(filesDir);
      files.sort((a, b) => a.localeCompare(b));
      return files;
    } catch (_) {
      console.error(_);
      return [];
    }
  }

  addNew(fileName: string) {
    const copy = Array.from(this.fileNames);
    copy.push(fileName);
    this.fileNames = copy;
  }

  deleteRecord(context: Context, fileName: string) {
    try {
      const filePath = context.filesDir + '/' + fileName;
      fs.unlinkSync(filePath);
      this.fileNames = this.fileNames.filter(name => name !== fileName);
    } catch (e) {
      console.error('deleteRecord err:', e);
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
      this.fileNames = this.fileNames.map(name => name === oldName ? finalNewName : name);
    } catch (e) {
      console.error('renameRecord err:', e);
    }
  }
}