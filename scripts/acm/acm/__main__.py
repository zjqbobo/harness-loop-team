"""ACM Agent 入口"""
from acm.reporter import Reporter
from acm.storage import LocalStore


def main():
    store = LocalStore()
    reporter = Reporter(store)
    reporter.run()


if __name__ == "__main__":
    main()
