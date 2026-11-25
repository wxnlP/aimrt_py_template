import datetime
import threading
import time

import aimrt_py as aimrt
import yaml


class AimRTPyModule(aimrt.ModuleBase):
    def __init__(self):
        super().__init__()
        # AimRT 对象
        self.core = aimrt.CoreRef()
        self.logger = aimrt.LoggerRef()
        self.work_executor = aimrt.ExecutorRef()

        self.stop_sig = threading.Event()

    def Info(self) -> aimrt.ModuleInfo:
        info = aimrt.ModuleInfo()
        info.name = "AimRTPyModule"
        return info

    def Initialize(self, core: aimrt.CoreRef) -> bool:
        self.core = core
        self.logger = self.core.GetLogger()

        # yaml 初始化
        file_path = self.core.GetConfigurator().GetConfigFilePath()
        with open(file_path, "r") as f:
            config = yaml.safe_load(f)
            work_executor_name = str(config["work_executor_name"])
            
        # 创建任务执行器
        self.work_executor = self.core.GetExecutorManager().GetExecutor(work_executor_name)

        return True

    def Start(self) -> bool:
        self.running = True
        self.work_executor.ExecuteAfter(datetime.timedelta(milliseconds=200), self.main_loop)
        
        aimrt.info(self.logger, "AimRTPyModule start success.")

        return True

    def Shutdown(self):
        self.running = False
        self.stop_sig.wait()

        aimrt.info(self.logger, "AimRTPyModule shutdown success.")

    def main_loop(self):
        count = 0    
        while self.running:
            count += 1
            aimrt.info(self.logger, f"aimrt_py module : {count}")
            time.sleep(1)
        self.stop_sig.set()
