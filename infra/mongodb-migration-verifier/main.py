import os
import pymongo
from typing import Dict, List
import json
from enum import Enum


MONGODB_SOURCE_URI = os.getenv("MONGODB_SOURCE_URI")
MONGODB_TARGET_URI = os.getenv("MONGODB_TARGET_URI")

DATABASE_NAME = "wave"

SKIP_VERIFIED_COLLECTIONS = set(["test"])


class ReportItemStatus(Enum):
    PASSED = 1
    FAILED = 2


class ReportItemReason(Enum):
    NONE = 0
    KEY_NOT_FOUND = 1
    TYPE_NOT_MATCHED = 2
    VAL_NOT_MATCHED = 3


class ReportItem(object):
    def __init__(self, key: str, status: ReportItemStatus, reason: ReportItemReason, src_val, target_val):
        self.key = key
        self.status = status
        self.src_val = src_val
        self.target_val = target_val


class Report(object):
    def __init__(self) -> None:
        self.items: List[ReportItem] = []
        self.total = 0
        self.passed = 0
        self.failed = 0

    def success(self, key, src_val, target_val):
        self.items.append(ReportItem(key, ReportItemStatus.PASSED,
                          ReportItemReason.NONE, src_val, target_val))
        self.total += 1
        self.passed += 1

    def fail(self, key, reason, src_val, target_val):
        self.items.append(ReportItem(
            key, ReportItemStatus.FAILED, reason, src_val, target_val))
        self.total += 1
        self.failed += 1

    def __str__(self) -> str:
        ret = ""
        for i in self.items:
            if i.status == ReportItemStatus.PASSED:
                ret += f"{i.key}: {i.status.name}\n"
            else:
                ret += f"{i.key}: {i.status.name}\n  >>> source: {i.src_val}\n  >>> target: {i.target_val}\n"

        ret += f"TOTAL: {self.total}, PASSED: {self.passed}, FAILED: {self.failed}"
        return ret


class VerificationSet(object):
    def __init__(self) -> None:
        self.items: Dict[str, int | str | List | set] = dict()

    def add_item(self, key, value):
        if key in self.items:
            raise Exception(f"key: {key} exists")

        self.items[key] = value

    def __str__(self) -> str:
        return json.dumps(self.__dict__, default=str)

    def verify(self, other) -> Report:
        ret = Report()
        for k, items in self.items.items():
            if k not in other.items:
                ret.fail(k, ReportItemReason.KEY_NOT_FOUND, items, None)
                continue
            other_items = other.items[k]
            if type(items) != type(other_items):
                ret.fail(k, ReportItemReason.TYPE_NOT_MATCHED,
                         items, other_items)
                continue

            if type(items) == list:
                src_set = {}
                target_set = {}
                for i in items:
                    src_set[i] = None
                for i in other_items:
                    target_set[i] = None
                if src_set != target_set:
                    ret.fail(k, ReportItemReason.VAL_NOT_MATCHED,
                             items, other_items)
                    continue
            else:
                if items != other_items:
                    ret.fail(k, ReportItemReason.VAL_NOT_MATCHED,
                             items, other_items)
                    continue

            ret.success(k, items, other_items)

        return ret


def main():
    src_verify_set = get_verification_set_by_uri(
        MONGODB_SOURCE_URI, DATABASE_NAME)
    target_verify_set = get_verification_set_by_uri(
        MONGODB_TARGET_URI, DATABASE_NAME)

    r = src_verify_set.verify(target_verify_set)
    print(r)


def get_verification_set_by_uri(mongo_uri: str, db_name: str) -> VerificationSet:
    cli = pymongo.MongoClient(mongo_uri)
    db = cli[db_name]
    coll_names = set(db.list_collection_names()) - SKIP_VERIFIED_COLLECTIONS
    vs = VerificationSet()
    vs.add_item("collections_names", coll_names)

    for name in coll_names:
        pfx = f"collection_{name}"
        stats = db.command("collStats", name)
        count = stats['count']
        vs.add_item(f"{pfx}.doc_count", count)
        vs.add_item(f"{pfx}.indexes",
                     get_indexes(stats['indexSizes']))
        vs.add_item(f"{pfx}.first_obj",
                     find_one(db[name], pymongo.ASCENDING))
        vs.add_item(f"{pfx}.last_obj",
                     find_one(db[name], pymongo.DESCENDING))

    return vs


def get_indexes(indexInfos: Dict) -> List[str]:
    indexes: List[str] = []
    for idx_name, _ in indexInfos.items():
        indexes.append(idx_name)

    return indexes


def find_one(collection, order):
    res = collection.find({}).sort("_id", order)
    for x in res:
        return x
    return None


if __name__ == "__main__":
    main()
