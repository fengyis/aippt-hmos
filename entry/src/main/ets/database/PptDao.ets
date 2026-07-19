import { relationalStore } from '@kit.ArkData'
import { PptDatabase } from './PptDatabase'
import { PPTCreateTable, PPTCollectTable } from '../model/DbModels'

export class PptCreateDao {
  static async insert(context: Context, record: PPTCreateTable): Promise<void> {
    const store = await PptDatabase.getStore(context)
    const valueBucket: relationalStore.ValuesBucket = {
      taskId: record.taskId, title: record.title, status: record.status,
      fileUrl: record.fileUrl, createTime: record.createTime
    }
    await store.insert('ppt_create', valueBucket)
  }

  static async queryAll(context: Context): Promise<PPTCreateTable[]> {
    const store = await PptDatabase.getStore(context)
    const predicates = new relationalStore.RdbPredicates('ppt_create')
    const resultSet = await store.query(predicates)
    const results: PPTCreateTable[] = []
    while (resultSet.goToNextRow()) {
      results.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')),
        taskId: resultSet.getString(resultSet.getColumnIndex('taskId')),
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        status: resultSet.getString(resultSet.getColumnIndex('status')),
        fileUrl: resultSet.getString(resultSet.getColumnIndex('fileUrl')),
        createTime: resultSet.getLong(resultSet.getColumnIndex('createTime'))
      } as PPTCreateTable)
    }
    resultSet.close()
    return results
  }

  static async deleteByIds(context: Context, ids: number[]): Promise<void> {
    const store = await PptDatabase.getStore(context)
    for (const id of ids) {
      const predicates = new relationalStore.RdbPredicates('ppt_create')
      predicates.equalTo('id', id)
      await store.delete(predicates)
    }
  }
}

export class PptCollectDao {
  static async insert(context: Context, record: PPTCollectTable): Promise<void> {
    const store = await PptDatabase.getStore(context)
    const valueBucket: relationalStore.ValuesBucket = {
      templateId: record.templateId, coverUrl: record.coverUrl,
      title: record.title, collectTime: record.collectTime
    }
    await store.insert('ppt_collect', valueBucket)
  }

  static async queryAll(context: Context): Promise<PPTCollectTable[]> {
    const store = await PptDatabase.getStore(context)
    const predicates = new relationalStore.RdbPredicates('ppt_collect')
    const resultSet = await store.query(predicates)
    const results: PPTCollectTable[] = []
    while (resultSet.goToNextRow()) {
      results.push({
        templateId: resultSet.getString(resultSet.getColumnIndex('templateId')),
        coverUrl: resultSet.getString(resultSet.getColumnIndex('coverUrl')),
        title: resultSet.getString(resultSet.getColumnIndex('title')),
        collectTime: resultSet.getLong(resultSet.getColumnIndex('collectTime'))
      } as PPTCollectTable)
    }
    resultSet.close()
    return results
  }
}
