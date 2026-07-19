import { relationalStore } from '@kit.ArkData'

const DB_NAME = 'PPT_DB'
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DB_NAME,
  securityLevel: relationalStore.SecurityLevel.S1
}

const SQL_CREATE_PPT_CREATE = `
CREATE TABLE IF NOT EXISTS ppt_create (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  taskId TEXT NOT NULL,
  title TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  fileUrl TEXT,
  createTime INTEGER NOT NULL
)`

const SQL_CREATE_PPT_COLLECT = `
CREATE TABLE IF NOT EXISTS ppt_collect (
  templateId TEXT PRIMARY KEY,
  coverUrl TEXT NOT NULL,
  title TEXT NOT NULL,
  collectTime INTEGER NOT NULL
)`

export class PptDatabase {
  private static store: relationalStore.RdbStore | null = null

  static async getStore(context: Context): Promise<relationalStore.RdbStore> {
    if (!PptDatabase.store) {
      PptDatabase.store = await relationalStore.getRdbStore(context, STORE_CONFIG)
      await PptDatabase.store.executeSql(SQL_CREATE_PPT_CREATE)
      await PptDatabase.store.executeSql(SQL_CREATE_PPT_COLLECT)
    }
    return PptDatabase.store
  }
}
