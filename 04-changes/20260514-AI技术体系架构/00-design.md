# AI Agent 平台 (aPaaS) — 多行业 AI 技术体系架构设计方案

**版本**: v2.11
**日期**: 2026-06-04
**状态**: 设计完成，待审阅。v2.11 新增：请求路由两层分工（Higress→Java后端→Agent Router）

---

## 目录

1. [概述与定位](#1-概述与定位)
2. [总体架构](#2-总体架构)
3. [基础设施层](#3-基础设施层)
4. [AI 能力层](#4-ai-能力层)
5. [Agent 平台层](#5-agent-平台层)
6. [行业解决方案层](#6-行业解决方案层)
7. [平台横切能力](#7-平台横切能力)
8. [技术选型矩阵](#8-技术选型矩阵)
9. [部署架构与演进路线](#9-部署架构与演进路线)
10. [从零搭建路线图](#10-从零搭建路线图)
11. [物流运输异常处理 Agent 完整案例](#11-物流运输异常处理-agent-完整案例)
12. [Agent 执行准确率提升体系](#12-agent-执行准确率提升体系)
13. [Java 技术栈集成方案](#13-java-技术栈集成方案)
14. [Prompt Hub 独立服务设计](#14-prompt-hub-独立服务设计)
15. [知识向量与原文存储关系](#15-知识向量与原文存储关系)
16. [会话三层存储原理与 Recall 决策逻辑](#16-会话三层存储原理与-recall-决策逻辑)
17. [A2A 协议与 Agent 自动发现](#17-a2a-协议与-agent-自动发现)
18. [技能市场：服务边界与发布生效机制](#18-技能市场服务边界与发布生效机制)

---

## 1. 概述与定位

### 1.1 产品定位

本产品定位为**面向多行业的 AI Agent 平台型产品（aPaaS — AI Platform as a Service）**，客户可基于平台自助构建、运行、管理面向自身业务的 AI Agent 和智能应用。

定位一句话：**让每个行业的企业都能像搭建 SaaS 工作流一样搭建 AI 数字员工。**

![AI Agent 平台产品定位](images/fw-arch-17-product-positioning.png)

### 1.2 目标客户画像

| 层级 | 典型客户 | 核心诉求 | 付费能力 |
|------|---------|---------|---------|
| **大型企业** | 行业龙头，年营收 10 亿+ | AI 能力私有化部署、行业 know-how 封装、安全合规 | 强，百万级/年 |
| **中型企业** | 行业腰部，年营收 1-10 亿 | 快速落地 AI 场景、开箱即用的行业 Agent 模板、降低 AI 人才门槛 | 中，10-50 万/年 |
| **ISV/伙伴** | 行业软件开发/咨询公司 | 基于平台二次开发行业方案、技能市场变现、联合交付 | 中等，按分成/授权 |

**初期切入行业**（依据团队基因选择）：
- **第一梯队**：物流/供应链（存量优势）、金融（高付费意愿 + 合规刚需）
- **第二梯队**：制造、零售、政务

### 1.3 核心价值主张

本平台填平的核心鸿沟：**"把大模型能力 → 封装成行业可用的数字员工 → 业务直接使用"**

| 价值点 | 传统方式 | 本平台方式 |
|--------|---------|-----------|
| **降门槛** | 需要 ML 工程师 + 后端 + 前端组队开发 | 业务人员可对话式构建 Agent，开发者可 Pro-Code 定制 |
| **行业化** | 通用模型+通用 Prompt，不懂行业术语和规则 | 行业知识库预置+行业连接器+行业 Agent 模板 |
| **可治理** | 黑盒调用，不知道 Agent 做了什么决策 | 全链路可观测+评估体系+合规审计 |

### 1.4 对标分析

| 维度 | 本平台 | Salesforce Agentforce | Manhattan Agent Foundry | Dify/Coze |
|------|--------|----------------------|------------------------|-----------|
| **行业深度** | ⭐⭐⭐⭐⭐ 多行业预置 | ⭐⭐⭐ CRM 行业 | ⭐⭐⭐⭐ 供应链行业 | ⭐ 通用 |
| **客户自建 Agent** | ⭐⭐⭐⭐⭐ 核心能力 | ⭐⭐⭐⭐ 自然语言+工具链 | ⭐⭐⭐⭐⭐ 三种构建路径 | ⭐⭐⭐⭐ 可视化 |
| **独立产品化** | ⭐⭐⭐⭐⭐ 独立售卖 | ❌ SF 生态绑定 | ❌ Manhattan Active 绑定 | ⭐⭐⭐ 开源/云 |
| **企业级安全** | ⭐⭐⭐⭐⭐ 私有化部署 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |
| **中国市场适配** | ⭐⭐⭐⭐⭐ | ⭐ | ⭐ | ⭐⭐ |
| **伙伴生态** | ⭐⭐ 起步阶段 | ⭐⭐⭐⭐⭐ AppExchange | ⭐⭐⭐ Agent Marketplace | ⭐⭐⭐ 插件市场 |

**差异化卡位**：在通用 Agent 平台（Dify/Coze）和国际垂直 Agent（Agentforce/Manhattan）之间，做一个**中国市场原生的、跨行业可复用的 AI Agent 平台层**。

---

## 2. 总体架构

### 2.1 四层融合架构全景

![AI Agent 平台四层融合架构全景](images/fw-arch-01-four-layer.png)

### 2.2 设计原则

| # | 原则 | 含义 | 架构体现 |
|---|------|------|---------|
| **P1** | **层次解耦** | 每一层有明确的接口契约，可独立演进和替换 | 层间通过标准 API/gRPC 通信，不允许跨层穿透调用 |
| **P2** | **Agent 原生** | 平台一切能力围绕 Agent 构建，"一切皆可被 Agent 调用" | 能力层全部封装为 Tool/Skill，Agent 通过统一协议调用 |
| **P3** | **行业可插拔** | 新行业接入无平台改造，通过配置+预置包完成 | 行业方案层与平台层解耦，通过 ISV SDK 和行业包机制 |
| **P4** | **企业级就绪** | 第一天就考虑多租户、安全、审计、高可用 | 横切能力层独立设计，不在业务逻辑中散落 |
| **P5** | **渐近式消费** | 客户可从任意一层进入，不必全栈采纳 | 每层提供独立 API，能力层和 Agent 层可独立售卖 |
| **P6** | **开放生态** | 不做 walled garden，拥抱标准协议 | 支持 MCP、A2A、OpenAI API 兼容协议 |

### 2.3 核心技术决策

| # | 决策点 | 选项 | 选择 | 理由 |
|---|--------|------|------|------|
| **D1** | Agent 框架 | LangGraph / CrewAI / 自研 | **自研轻量引擎 + LangGraph 内核** | 需要深度定制（多 Agent 协作、行业工作流），但复用社区的图编排能力 |
| **D2** | 模型接入模式 | 单一供应商 / 多模型网关 | **多模型网关** | 客户需要模型选择自由，且不同场景最优模型不同 |
| **D3** | 内存/状态管理 | 无状态 / 有状态 Agent | **有状态 + 分层记忆** | B2B 场景需要长对话上下文、跨会话记忆、行业知识持久化 |
| **D4** | 技能扩展机制 | 代码级插件 / 声明式配置 | **声明式 + 代码级双模** | 简单技能声明式（API 调用），复杂技能支持自定义代码 |
| **D5** | 部署模式 | 纯 SaaS / 纯私有化 / 混合 | **混合部署** | 大客户需要私有化（数据不出域），中小企业接受 SaaS |
| **D6** | 多租户隔离 | 逻辑隔离 / 物理隔离 | **逻辑隔离 + 可升级物理隔离** | 中小客户逻辑隔离降成本，大客户可选专属实例 |
| **D7** | 消息协议 | REST / gRPC / MCP / A2A | **多协议共存** | REST=外部集成, gRPC=内部服务, MCP=技能连接, A2A=Agent 间通信 |

### 2.4 请求链路全景

![请求链路全景](images/fw-flow-02-request-chain.png)

---

## 3. 基础设施层

### 3.1 定位与边界

基础设施层的职责：**为上层提供稳定、弹性、安全的算力与数据底座**，对上层完全透明——上层不感知 GPU 是 A100 还是 H100，不感知向量库是 Milvus 还是 Qdrant。

### 3.2 GPU 推理集群

#### 3.2.1 总览

![GPU 推理集群调度架构](images/fw-arch-04-gpu-cluster.png)

| 能力 | 设计 | 说明 |
|------|------|------|
| **模型冷热管理** | 三级缓存调度 | Hot(常驻 GPU) → Warm(5s 加载) → Cold(按需拉取，30s) |
| **GPU 亲和性** | 同模型请求尽量路由到同一 GPU | 复用 KV Cache，延迟降低 40%+ |
| **优先级抢占** | 在线推理 > 离线评估 > 模型训练 | 保障生产 SLA，离线任务填充空闲算力 |
| **弹性伸缩** | HPA 基于队列深度 + GPU 利用率 | 最小 0（无请求零成本），最大配额内自动扩 |
| **异构支持** | NVIDIA + 国产芯片（昇腾/寒武纪） | 信创合规客户可选国产芯片池 |

#### 3.2.2 GPU 集群软件栈——裸机之上的每一层

GPU 物理机器到可对外提供推理服务，中间需要部署多层软件：

```
Layer 6: 推理服务 API (OpenAI 兼容 /v1/chat/completions)
         ↑
Layer 5: 推理引擎 (vLLM / TGI / TensorRT-LLM / Triton Server)
         ↑
Layer 4: 模型管理器 (Model Manager — 加载/卸载/版本切换/缓存)
         ↑
Layer 3: K8s GPU Operator (Device Plugin + DCGM + GPU Feature Discovery)
         ↑
Layer 2: 容器运行时 (nvidia-container-toolkit + containerd/docker)
         ↑
Layer 1: NVIDIA GPU Driver + CUDA Toolkit
         ↑
Layer 0: 裸机硬件 (GPU 物理卡 + NVLink/PCIe + 内存 + NVMe SSD)
```

| 层次 | 组件 | 部署方式 | 作用 |
|------|------|---------|------|
| **L0 硬件** | GPU 物理卡、NVLink、NVMe SSD | — | 算力底座 |
| **L1 驱动** | NVIDIA GPU Driver + CUDA Toolkit | 每台 GPU 节点安装，rpm/deb 包 | 操作系统识别 GPU、提供 CUDA 运行时 |
| **L2 容器运行时** | nvidia-container-toolkit + containerd | 每台 GPU 节点安装 | 容器内访问 GPU（注入 `nvidia.com/gpu` 设备） |
| **L3 K8s GPU 感知** | GPU Operator (Device Plugin + DCGM + Feature Discovery) | K8s DaemonSet | K8s 调度器感知 GPU 资源、监控 GPU 健康状态、自动打标签 |
| **L4 模型管理器** | 自研模型热插拔服务 | K8s Deployment | 模型下载/加载到 GPU 显存/卸载/版本切换/缓存预热 |
| **L5 推理引擎** | vLLM / TGI / TensorRT-LLM | K8s Deployment (每模型一个) | 接收 /v1/chat/completions 请求 → GPU 推理 → 返回 token 流 |
| **L6 推理 API** | Model Gateway (LiteLLM 内核) | K8s Deployment | 统一 OpenAI API 兼容入口、路由、Fallback、限流 |

#### 3.2.3 各层详细部署设计

**Layer 1: GPU 驱动安装**

```bash
# 每台 GPU 节点执行一次
# 安装 NVIDIA Driver
apt-get install -y nvidia-driver-550

# 安装 CUDA Toolkit (推理不需要完整的 CUDA，runtime 即可)
apt-get install -y cuda-runtime-12-4

# 验证
nvidia-smi
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 550.xx    Driver Version: 550.xx    CUDA Version: 12.4     |
# |-------------------------------+----------------------+----------------------+
# | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
# | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
# |===============================+======================+======================|
# |   0  NVIDIA A100-SXM...  On   | 00000000:07:00.0 Off |                    0 |
# | N/A   34C    P0    52W / 400W |      0MiB / 81920MiB |      0%      Default |
# +-------------------------------+----------------------+----------------------+
```

**Layer 2: 容器运行时——让 Docker 容器能访问 GPU**

```bash
# 安装 nvidia-container-toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update && apt-get install -y nvidia-container-toolkit

# 配置 containerd（K8s 默认容器运行时）
nvidia-ctk runtime configure --runtime=containerd
systemctl restart containerd

# 测试 GPU 容器访问
docker run --rm --gpus all nvidia/cuda:12.4.0-runtime-ubuntu22.04 nvidia-smi
```

**Layer 3: K8s GPU Operator——让 K8s 感知和管理 GPU**

```bash
# 通过 Helm 安装 NVIDIA GPU Operator
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator --create-namespace \
  --set driver.enabled=false \           # 驱动已手动安装，跳过
  --set toolkit.enabled=true \           # 启用容器工具集
  --set devicePlugin.enabled=true \      # 启用设备插件(K8s感知GPU)
  --set dcgm.enabled=true \             # 启用GPU监控
  --set dcgmExporter.enabled=true \     # 启用 Prometheus GPU 指标导出
  --set gfd.enabled=true                # GPU Feature Discovery(自动打标签)

# 验证 K8s 节点 GPU 资源
kubectl describe node gpu-node-01 | grep nvidia.com/gpu
#   nvidia.com/gpu:     8          ← K8s 识别到 8 张 GPU
#   nvidia.com/gpu.memory: 81920   ← 每张 80GB 显存

# GPU Feature Discovery 自动打上的标签
kubectl get node gpu-node-01 --show-labels | tr ',' '\n' | grep nvidia
# nvidia.com/gpu.product=NVIDIA-A100-SXM4-80GB
# nvidia.com/gpu.memory=81920
# nvidia.com/gpu.count=8
# nvidia.com/cuda.driver.major=550
```

**Layer 4: 模型管理器——模型生命周期管理**

模型管理器是 GPU 集群独有的一层——大模型体积巨大（DeepSeek-V3 约 700GB，Qwen-72B 约 150GB），不可能每次请求都临时加载，需要精细的加载/卸载/缓存策略。

```python
class ModelManager:
    """大模型生命周期管理器"""
    
    def __init__(self, model_registry: S3Client, gpu_cluster: K8sClient):
        self.registry = model_registry
        self.gpu_cluster = gpu_cluster
        self.model_cache: dict[str, ModelState] = {}
    
    # === 模型存储: 原始权重 → 本地高速缓存 → GPU 显存 ===
    
    async def ensure_model_loaded(self, model_name: str, target_state: str = "hot") -> str:
        """
        确保模型处于目标状态:
          cold: 仅在 S3 对象存储中
          warm: 下载到本地 NVMe SSD 缓存, 不占用 GPU 显存
          hot:  加载到 GPU 显存, 可立即推理
        """
        state = self.model_cache.get(model_name, ModelState.COLD)
        
        if state == ModelState.COLD:
            # Step 1: S3 → 本地 NVMe SSD (warm)
            await self._download_to_local_cache(model_name)
            state = ModelState.WARM
            self.model_cache[model_name] = state
        
        if target_state == "hot" and state == ModelState.WARM:
            # Step 2: 本地 NVMe SSD → GPU 显存 (hot)
            # 触发推理引擎 Deployment 启动并加载模型
            await self.gpu_cluster.scale_up(model_name, replicas=1)
            await self._wait_until_ready(model_name)
            state = ModelState.HOT
            self.model_cache[model_name] = state
        
        return state
    
    async def _download_to_local_cache(self, model_name: str):
        """S3 → 节点本地 NVMe SSD"""
        # 模型可能非常大 (DeepSeek-V3 ~700GB)
        # 使用节点本地 NVMe SSD (3-7 GB/s 读取) 而非网络存储 (NFS 瓶颈)
        local_path = f"/mnt/nvme/models/{model_name}"
        
        # 检查本地缓存
        if os.path.exists(local_path):
            return  # 已缓存
        
        # 从 S3 下载 (并行, 多线程)
        await self.registry.download(
            bucket="ai-platform-models",
            prefix=model_name,
            local_path=local_path,
            threads=16  # 并行下载加速
        )
    
    async def unload_model(self, model_name: str):
        """卸载模型——释放 GPU 显存"""
        await self.gpu_cluster.scale_down(model_name, replicas=0)
        self.model_cache[model_name] = ModelState.WARM  # 不删本地缓存
    
    # === 冷热调度策略 ===
    
    class ModelState(Enum):
        COLD = "cold"   # 仅 S3, 首次加载约 30s
        WARM = "warm"   # 本地 NVMe SSD, 加载到 GPU 约 5s
        HOT  = "hot"    # GPU 显存中, 推理延迟 < 100ms (不含 LLM 耗时)
    
    async def auto_tier(self):
        """根据模型访问热度自动调整冷热状态"""
        stats = await self._get_model_stats()
        
        for model_name, stat in stats.items():
            if stat["requests_last_5min"] > 10:
                # 高频访问 → 保持 hot
                await self.ensure_model_loaded(model_name, "hot")
            elif stat["requests_last_30min"] == 0:
                # 30 分钟无访问 → 卸载到 warm
                await self.unload_model(model_name)
            elif stat["requests_last_24h"] == 0:
                # 24 小时无访问 → 清理本地缓存到 cold
                await self._clean_local_cache(model_name)
```

**模型存储的分级策略：**

```
S3/MinIO (cold, ~500ms 首字节延迟 + 下载时间)
    │ 首次加载: 下载到本地 (DeepSeek-V3 ~30s)
    ▼
本地 NVMe SSD (warm, ~5s 加载到 GPU)
    │ 预热: 加载到 GPU 显存
    ▼
GPU HBM 显存 (hot, ~10ms 首 token 延迟)
    │ 推理: Token-by-token 生成
    ▼
KV Cache (GPU 显存驻留, 复用)
```

```bash
# Kubernetes PersistentVolume——本地 NVMe SSD (highest I/O)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: model-cache-gpu-01
spec:
  capacity:
    storage: 2Ti
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-nvme
  local:
    path: /mnt/nvme/models
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: nvidia.com/gpu.product
          operator: In
          values: [NVIDIA-A100-SXM4-80GB]
```

**Layer 5: 推理引擎——接收 HTTP 请求 → GPU 推理 → 返回 token**

| 推理引擎 | 适用场景 | 核心特性 | 部署方式 |
|---------|---------|---------|---------|
| **vLLM** | 高吞吐在线推理（主力） | PagedAttention 高效管理 KV Cache、Continuous Batching、OpenAI API 兼容 | K8s Deployment（每模型 1 个） |
| **TGI (Text Generation Inference)** | HuggingFace 生态、快速实验 | HuggingFace 原生支持、支持多种量化 | K8s Deployment（实验/验证） |
| **TensorRT-LLM** | 极致性能优化 | NVIDIA 官方优化、FP8/INT4 量化、对 A100/H100 深度调优 | K8s Deployment（高负载生产） |
| **Triton Inference Server** | 多模型混合推理 | NVIDIA 出品、支持多框架（ONNX/TensorFlow/PyTorch）、动态批处理 | K8s Deployment（多模型混部） |

```yaml
# 生产环境 vLLM 部署 (DeepSeek-V3)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-deepseek-v3
  namespace: ai-platform
spec:
  replicas: 1  # 单副本即可（内部 Continuous Batching + PagedAttention 已充分利用 GPU）
  selector:
    matchLabels:
      app: vllm-deepseek-v3
  template:
    metadata:
      labels:
        app: vllm-deepseek-v3
    spec:
      nodeSelector:
        nvidia.com/gpu.product: NVIDIA-A100-SXM4-80GB  # 指定 GPU 型号
      containers:
      - name: vllm
        image: vllm/vllm-openai:v0.6.0
        args:
        - --model /models/DeepSeek-V3           # 模型本地路径
        - --tensor-parallel-size 4              # 4 张 GPU 做张量并行
        - --gpu-memory-utilization 0.90         # 90% 显存用于 KV Cache
        - --max-model-len 32768                 # 最大上下文长度
        - --max-num-seqs 128                    # 最大并发请求数
        - --enable-prefix-caching               # 启用前缀缓存 (System Prompt 复用)
        ports:
        - containerPort: 8000
        env:
        - name: HUGGING_FACE_HUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: hf-token
              key: token
        resources:
          limits:
            nvidia.com/gpu: 4                   # 独占 4 张 GPU
          requests:
            nvidia.com/gpu: 4
        volumeMounts:
        - name: model-cache
          mountPath: /models                     # 模型文件挂载 (本地 NVMe SSD)
        - name: shm
          mountPath: /dev/shm                    # 共享内存 (多 GPU 通信需要)
      volumes:
      - name: model-cache
        persistentVolumeClaim:
          claimName: model-cache-gpu-01
      - name: shm
        emptyDir:
          medium: Memory
          sizeLimit: 64Gi                        # 多 GPU 通信需要大共享内存

---
# Service 暴露
apiVersion: v1
kind: Service
metadata:
  name: vllm-deepseek-v3
spec:
  selector:
    app: vllm-deepseek-v3
  ports:
  - port: 8000
    targetPort: 8000
```

#### 3.2.4 请求调度与 GPU 亲和性路由

```
请求到达 Model Gateway
    │
    ▼
调度器查询: "这个请求想调 DeepSeek-V3"
    │
    ├── 已有 Pod 运行 DeepSeek-V3 → 检查 Pod 负载
    │   ├── 负载 < 80% → 路由到该 Pod (复用 KV Cache)
    │   └── 负载 > 80% → 触发扩容新 Pod
    │
    ├── 无 Pod 运行 DeepSeek-V3 → 触发模型管理器加载
    │   ├── 本地有缓存 (warm) → 创建 Pod (5s 就绪)
    │   └── 无缓存 (cold) → 下载 + 创建 Pod (30s 就绪)
    │
    └── 所有 Pod 都不可用 → Fallback 到备选模型
```

```python
class GPUScheduler:
    """GPU 推理调度器——比普通 HTTP 负载均衡多一层 GPU 语义"""
    
    async def route_request(self, model_name: str, request: dict) -> str:
        """返回目标 Pod IP"""
        
        pods = await self.k8s.list_pods(
            label_selector=f"app=vllm-{model_name}"
        )
        
        if not pods:
            # 无 Pod → 触发加载
            await self.model_manager.ensure_model_loaded(model_name, "hot")
            return await self._wait_and_route(model_name)
        
        # 选择策略: KV Cache 亲和性优先
        best_pod = None
        best_score = float('-inf')
        
        for pod in pods:
            score = 0
            
            # KV Cache 命中率估算 (同一 session 的请求路由到同一 Pod)
            session_id = request.get("session_id")
            if session_id and self._has_kv_cache(pod, session_id):
                score += 100  # 最高优先级: KV Cache 命中
            
            # GPU 显存剩余率
            mem_free = self._get_gpu_memory_free(pod)
            score += mem_free * 0.5
            
            # 当前并发请求数
            active = self._get_active_requests(pod)
            score -= active * 0.3
            
            if score > best_score:
                best_score = score
                best_pod = pod
        
        return best_pod["ip"]
```

#### 3.2.5 弹性伸缩策略

```yaml
# KEDA ScaledObject——基于 GPU 指标的弹性伸缩
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: vllm-deepseek-v3-autoscaler
  namespace: ai-platform
spec:
  scaleTargetRef:
    name: vllm-deepseek-v3
  minReplicaCount: 0       # 无请求时缩到 0 (GPU 释放)
  maxReplicaCount: 4       # 最多 4 副本 (4×4=16 张 GPU)
  
  triggers:
  # 触发器1: 请求队列深度
  - type: prometheus
    metadata:
      serverAddress: http://prometheus.monitoring:9090
      metricName: vllm_request_queue_depth
      threshold: "50"       # 队列深度 > 50 → 扩容
      query: |
        avg(vllm:request_queue_depth{model="deepseek-v3"})
  
  # 触发器2: GPU 利用率
  - type: prometheus
    metadata:
      serverAddress: http://prometheus.monitoring:9090
      metricName: gpu_utilization
      threshold: "85"       # GPU 利用率 > 85% → 扩容
      query: |
        avg(DCGM_FI_DEV_GPU_UTIL{model="deepseek-v3"})
  
  advanced:
    horizontalPodAutoscalerConfig:
      behavior:
        scaleDown:
          stabilizationWindowSeconds: 300  # 冷却 5 分钟再缩容
          policies:
          - type: Percent
            value: 50
            periodSeconds: 60
        scaleUp:
          stabilizationWindowSeconds: 30   # 快速扩容
          policies:
          - type: Pods
            value: 1
            periodSeconds: 30
```

#### 3.2.6 GPU 监控体系

```
每张 GPU 需要采集的指标:
┌────────────────────────────────────────────────────────────┐
│                                                              │
│  DCGM (NVIDIA Data Center GPU Manager) → Prometheus          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ DCGM_FI_DEV_GPU_UTIL          GPU 利用率             │   │
│  │ DCGM_FI_DEV_FB_USED           显存使用量 (GB)        │   │
│  │ DCGM_FI_DEV_FB_FREE           显存剩余量 (GB)        │   │
│  │ DCGM_FI_DEV_GPU_TEMP          GPU 温度 (°C)          │   │
│  │ DCGM_FI_DEV_POWER_USAGE       功耗 (W)               │   │
│  │ DCGM_FI_DEV_SM_CLOCK          SM 时钟频率            │   │
│  │ DCGM_FI_DEV_XID_ERRORS        XID 错误 (硬件故障)    │   │
│  │ DCGM_FI_DEV_ECC_ERRORS        ECC 纠错错误数         │   │
│  │ DCGM_FI_DEV_PCIE_REPLAY       PCIe 重传次数          │   │
│  │ DCGM_FI_DEV_NVLINK_BANDWIDTH  NVLink 带宽利用率      │   │
│  │ DCGM_FI_DEV_FB_USED_PERCENT   显存使用百分比         │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  vLLM Prometheus Metrics (推理应用层)                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ vllm:request_success_total      请求成功总数         │   │
│  │ vllm:request_duration_seconds   请求延迟 (P50/P95/P99)│   │
│  │ vllm:num_requests_running       当前运行中请求数       │   │
│  │ vllm:num_requests_waiting       队列等待中请求数       │   │
│  │ vllm:gpu_cache_usage_perc       KV Cache 使用率       │   │
│  │ vllm:num_preemptions_total      抢占次数               │   │
│  │ vllm:prompt_tokens_total        总 Prompt Token        │   │
│  │ vllm:generation_tokens_total    总生成 Token            │   │
│  │ vllm:time_to_first_token        首 Token 延迟           │   │
│  │ vllm:time_per_output_token      每 Token 延迟           │   │
│  └──────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

```yaml
# Prometheus GPU 告警规则
groups:
  - name: gpu_alerts
    rules:
      - alert: GPUUtilizationHigh
        expr: DCGM_FI_DEV_GPU_UTIL > 95
        for: 5m
        severity: warning
        annotations:
          summary: "GPU 利用率 >95% 持续 5 分钟"
      
      - alert: GPUMemoryExhausted
        expr: DCGM_FI_DEV_FB_USED / DCGM_FI_DEV_FB_TOTAL > 0.95
        for: 2m
        severity: critical
        annotations:
          summary: "GPU 显存使用超过 95%"
      
      - alert: GPUTemperatureHigh
        expr: DCGM_FI_DEV_GPU_TEMP > 85
        for: 5m
        severity: critical
        annotations:
          summary: "GPU 温度超过 85°C, 可能触发降频"
      
      - alert: GPUHardwareError
        expr: rate(DCGM_FI_DEV_XID_ERRORS[5m]) > 0
        severity: critical
        annotations:
          summary: "检测到 GPU XID 硬件错误"
      
      - alert: ModelLoadFailure
        expr: model_load_failures_total > 0
        severity: critical
        annotations:
          summary: "模型加载失败"
```

#### 3.2.7 GPU 节点规划建议

**单节点规格（以 A100-80GB × 8 为例）：**

| 组件 | 规格 | 说明 |
|------|------|------|
| GPU | 8 × A100-SXM4-80GB | NVLink 互联 |
| CPU | 2 × AMD EPYC 7763 (64核) | GPU 节点 CPU 需求不高 |
| 内存 | 512 GB DDR4 | 模型加载时暂存 + 系统开销 |
| 本地存储 | 2 × 3.84TB NVMe SSD (RAID 0) | 模型文件缓存 (单模型 ~700GB) |
| 网络 | 1 × 100Gbps Mellanox ConnectX-6 | 模型下载 + 推理请求 |
| GPU 互联 | NVLink 600GB/s | 张量并行通信 |

**集群规模建议（按日请求量）：**

| 日请求量 | A100-80GB 节点数 | 可同时加载模型数 | 部署方式 |
|---------|:---:|:---:|---|
| < 10 万 | 2 | 2-4 个 | 单 K8s 集群 |
| 10-50 万 | 4-8 | 6-12 个 | 多 GPU 节点池 |
| 50-200 万 | 10-20 | 15-30 个 | 多 GPU 节点池 + 模型分组 |
| > 200 万 | 20+ | 按需 | 独立 GPU 集群 + 联邦调度 |

#### 3.2.8 高可用与容灾

```
┌──────────────────────────────────────────────────────────┐
│ GPU 推理高可用三层保障                                     │
│                                                          │
│  层级1: 模型级容错                                        │
│  ┌────────────────────────────────────────────────────┐  │
│  │ · 同一模型至少 2 个 GPU Pod（跨节点部署）              │  │
│  │ · 单 Pod 故障 → K8s 自动重建 (30s 就绪)              │  │
│  │ · Pod 重建期间请求路由到其他可用 Pod                  │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  层级2: 模型级故障转移                                    │
│  ┌────────────────────────────────────────────────────┐  │
│  │ · 主模型 (DeepSeek-V3) 不可用                       │  │
│  │   → Fallback 到备选模型 (Qwen-Plus / GPT-4o-mini)  │  │
│  │ · Model Gateway 自动切换 (对调用方透明)              │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  层级3: 硬件级冗余                                        │
│  ┌────────────────────────────────────────────────────┐  │
│  │ · 多 GPU 节点 (同一模型不部署在同一节点)              │  │
│  │ · GPU 节点故障 → 模型自动迁移到健康节点               │  │
│  │ · 国产芯片池作为兜底 (当 NVIDIA 集群满负载时)         │  │
│  └────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

#### 3.2.9 国产芯片适配

```yaml
# K8s 通过节点标签区分芯片类型，调度器自动适配
节点标签:
  accelerator: nvidia-a100     → 使用 vLLM (CUDA)
  accelerator: ascend-910b     → 使用 MindSpore 推理引擎
  accelerator: cambricon-mlu   → 使用寒武纪 Cambricon Neuware

# 模型镜像按芯片类型构建
model_images:
  deepseek-v3-cuda:     "registry/models/deepseek-v3:cuda-12.4"
  deepseek-v3-ascend:   "registry/models/deepseek-v3:ascend-cann-8.0"
  
# 调度策略
scheduling:
  # 优先 NVIDIA (性能最优)，兜底国产芯片
  nodeAffinity:
    preferred:
    - weight: 100
      matchExpressions:
      - key: accelerator
        operator: In
        values: [nvidia-a100, nvidia-h100]
    - weight: 50
      matchExpressions:
      - key: accelerator
        operator: In
        values: [ascend-910b]
```

#### 3.2.10 云厂商 GPU 节点——哪些层不需要自己管

使用云厂商 GPU K8s 节点（如阿里云 ACK、华为云 CCE、腾讯云 TKE）时，L0-L3 由云厂商提供，只需要管 L4-L6：

```
┌──────────────────────────────────────────────────────────────────┐
│  云厂商负责 (L0-L3)              │  你需要负责 (L4-L6)             │
│                                  │                               │
│  L0: 物理硬件                     │  L4: 模型管理器                 │
│    GPU/NVLink/NVMe SSD/网络       │    模型下载/加载/卸载/冷热调度    │
│                                  │                               │
│  L1: GPU 驱动 + CUDA             │  L5: 推理引擎                  │
│    (GPU 节点镜像预装)             │    vLLM/TGI Deployment 部署     │
│                                  │                               │
│  L2: 容器运行时                   │  L6: 推理 API                  │
│    (节点加入集群时自动配置)         │    Model Gateway 路由策略       │
│                                  │                               │
│  L3: K8s GPU 感知                │                               │
│    (阿里云ACK自动部署device-       │                               │
│     plugin;华为云CCE预装          │                               │
│     昇腾插件;腾讯云TKE通过         │                               │
│     gpu-manager自动安装)           │                               │
└──────────────────────────────────────────────────────────────────┘
```

| 层次 | 谁负责 | 云厂商具体做了什么 |
|:---:|:---:|------|
| **L0 硬件** | 云厂商 | 你买的是云主机，看不到物理机器。GPU 硬件故障由云厂商自动迁移 |
| **L1 GPU 驱动** | 云厂商 | 选 GPU 节点镜像时已预装。阿里云 `ack-ai-installer` 镜像自带 NVIDIA 550 + CUDA 12.4；华为云 CCE 镜像预装昇腾 CANN |
| **L2 容器运行时** | 云厂商 | GPU 节点加入 K8s 集群时自动配置好 `nvidia-container-toolkit` + `containerd` |
| **L3 GPU Operator** | 云厂商 | 阿里云 ACK 自动部署 `nvidia-device-plugin`；华为云 CCE 预装昇腾 `device-plugin`；腾讯云 TKE 通过 `gpu-manager` 自动安装。不需要手动 `helm install gpu-operator` |
| **L4 模型管理器** | **你** | 云厂商不知道你用什么模型、访问模式是怎样的，没法替你管理模型冷热调度 |
| **L5 推理引擎** | **你** | 部署 vLLM/TGI Deployment，配置张量并行度、显存分配策略、最大并发数——这些参数取决于你的业务场景，云厂商无法替你决策 |
| **L6 推理 API** | **你** | Model Gateway 的路由策略、Fallback 链、语义缓存——全是业务逻辑 |

**实际部署简化后，只需要做的事：**

```bash
# 1. 创建 GPU 节点池 (云厂商控制台操作)
# 阿里云 ACK: 选择 GPU 规格 (如 ecs.gn7i-c16g1.4xlarge) + ack-ai-installer 镜像
# 华为云 CCE: 选择 GPU 加速型 + GPU 节点镜像
# 腾讯云 TKE: 选择 GPU 计算型 + TKE GPU 镜像

# 2. 验证 GPU 已就绪 (节点加入集群后自动完成 L1-L3)
kubectl describe node gpu-node-01 | grep nvidia.com/gpu
# nvidia.com/gpu: 8   ← 云厂商已配好，直接可用

# 3. 部署模型管理器 (你需要做的)
kubectl apply -f model-manager-deployment.yaml

# 4. 部署推理引擎 vLLM (你需要做的)
kubectl apply -f vllm-deepseek-v3-deployment.yaml

# 5. 配置 Model Gateway 路由到 vLLM Service (你需要做的)
kubectl apply -f model-gateway-config.yaml
```

#### 3.2.11 模型数据生命周期——模型不是软件栈的一层

模型（如 DeepSeek-V3 ~700GB、Qwen-72B ~150GB）不是 GPU 软件栈中的某一层——它是**数据**，是在各层之间流转的 payload。类似于数据库的表数据不是数据库软件本身，模型是 GPU 集群的"业务数据"。

```
                    模型流转路径
                    
  对象存储 (S3/MinIO)          ← Cold: 模型文件 (权重/配置/tokenizer)
       │                         模型以文件形式存在，不占用 GPU 资源
       │  L4 模型管理器: 触发下载
       ▼                       
  本地 NVMe SSD               ← Warm: 缓存到节点本地
       │                         加载到 GPU 只需 5s
       │  L5 推理引擎 (vLLM): 加载权重到 GPU 显存
       ▼                       
  GPU HBM 显存                 ← Hot: 可立即推理
       │                         占用显存，推理延迟最低
```

| 模型的什么 | 谁管 | 说明 |
|-----------|:---:|------|
| 模型文件下载（从哪里获取） | **你** | 你决定用什么模型 (DeepSeek-V3 / Qwen-72B / 自训练模型)，从 HuggingFace/ModelScope 下载到你的对象存储 |
| 模型文件存储 (S3/MinIO) | **你** | 属于你的对象存储 bucket，云厂商只提供存储产品 |
| 模型冷热调度逻辑 | **你** | L4 模型管理器完全自研：什么时候加载、什么时候卸载、哪些模型常驻 GPU，取决于你的业务访问模式 |
| 模型加载到 GPU 显存 | **你** | vLLM 启动时执行 `--model /models/DeepSeek-V3` 加载权重文件到 GPU 显存 |
| GPU 显存（物理介质） | 云厂商 | HBM 是 GPU 硬件的一部分，云厂商负责硬件可用性 |

**模型存储与基础设施存储的关系：**

模型文件存在对象存储（MinIO/S3，§3.6），与知识库原文、审计归档共用同一存储基础设施。但访问模式不同：

| | 模型文件 | 知识库原文 |
|---|---|---|
| **大小** | 150GB-700GB (单模型) | KB-MB (单文档) |
| **访问模式** | 低频——首次部署时下载一次，版本更新时替换 | 高频——每次 RAG 检索都可能读取 |
| **本地缓存** | 必须有 (NVMe SSD)，否则加载 30s+ | 不需要（检索延迟可接受） |
| **版本管理** | 模型版本 (v3/v3.1) | 文档版本 (updated_at) |

### 3.3 向量数据库

![向量数据库代理与事件总线架构](images/fw-arch-05-vector-db-eventbus.png)

| 存储类型 | 选型 | 用途 | 规模设计 |
|---------|------|------|---------|
| **主向量存储** | Milvus (分布式) | 行业知识库、Long-term Memory、技能索引 | 单租户隔离 Collection，支持十亿级 |
| **热数据缓存** | Qdrant (单节点) | 最近 7 天会话向量、高频检索缓存 | 内存映射，P99 < 5ms |
| **混合检索** | Elasticsearch | BM25 关键词 + 向量混合召回 | 与 Milvus 互补，覆盖精确匹配场景 |

**多租户隔离策略**：
```
Collection 粒度：
  SaaS 客户 → 共享 Collection + partition_key 隔离（降低成本）
  私有化客户 → 独立 Collection（物理隔离）
```

### 3.4 图数据库

| 数据类别 | 存储 | 典型查询 |
|---------|------|---------|
| 行业知识图谱 | Neo4j | "客户 A 的供应商 B 在去年 Q4 的准时率？" → 实体-关系-属性链 |
| Agent 协作拓扑 | Neo4j | 多 Agent 编排的 DAG 依赖、循环检测 |
| 权限关系图 | PostgreSQL + 递归 CTE | "此用户能访问哪些 Agent 的执行结果？" |
| 技能依赖图 | Neo4j | "更新技能 X 会影响哪些 Agent？" → 影响分析 |

### 3.5 消息中间件

![事件总线架构 (Kafka)](images/fw-arch-05-vector-db-eventbus.png)

**设计要点**：
- **Agent 事件溯源**：所有 Agent 状态变更写入事件流，支持重放和回溯
- **异步解耦**：Agent 执行 → 评估 → 计费 → 审计，通过事件流异步串联，不阻塞主链路
- **可靠投递**：At-least-once + 幂等消费、死信队列（DLQ）兜底

### 3.6 对象存储与关系数据库

**数据存储矩阵（详见下表）：**

### 3.7 安全网关

![安全网关链路](images/fw-flow-07-security-gateway.png)

| 安全层次 | 组件 | 职责 |
|---------|------|------|
| **边缘防护** | WAF + API Gateway | 防 DDoS、IP 黑白名单、TLS 终结 |
| **身份认证** | Keycloak / Auth0 | OIDC/OAuth2.0、SAML 企业 SSO、MFA |
| **权限控制** | OpenFGA / OPA | RBAC(角色) + ABAC(属性) + ReBAC(关系) |
| **内容安全** | LLM Firewall (自研) | 输入检测(Prompt Injection / Jailbreak)、输出检测(敏感信息泄露 / 有害内容) |
| **数据安全** | 加解密服务 + KMS | 传输 TLS 1.3、存储 AES-256、密钥轮换 |

### 3.8 可观测性

**可观测性三支柱：**

**Metrics (Prometheus + Grafana)**
- 模型网关: 请求量/延迟(P50/P95/P99)/错误率/Token 消耗
- GPU 集群: GPU 利用率/显存/温度/队列深度
- Agent: 成功率/平均步数/耗时/Token 效率
- 业务: Agent 活跃数/客户使用量/SLA 达标率

**Tracing (OpenTelemetry + Jaeger)**
- Agent 执行链路: 用户请求 → Agent Router → LLM → Tool
- RAG 召回链路: Query → Embedding → Search → Rerank
- 模型调用链路: Gateway → Router → Engine → Response

**Logging (Loki + 结构化日志)**
- Agent 步骤日志 (JSON Schema 标准化)
- 模型调用日志 (Prompt + Response + Token 统计)
- 审计日志 (谁/何时/做了什么) → 合规必备
- 错误日志 (堆栈 + 上下文快照)

**Agent 专属可观测性**（区别于传统微服务）：

| 独有指标 | 说明 |
|---------|------|
| **Agent 成功率** | Agent 任务完成率（含部分成功 / 降级完成） |
| **幻觉率** | 引用来源与生成内容的一致性评分 |
| **Tool 调用准确率** | 是否在正确时机选择了正确的 Tool |
| **Token 效率** | 完成任务的实际 Token 消耗 vs 预算 |
| **用户干预率** | Agent 执行中需要人工介入的频率 |

---

## 4. AI 能力层

### 4.1 定位与边界

AI 能力层是平台的**技术中台**，给 Agent 层提供原子化的 AI 能力：模型调用、知识检索、Prompt 管理、知识图谱查询。

核心原则：**能力原子化、接口标准化、质量可度量**。每一能力模块独立部署、独立 scaling、独立计费。

### 4.2 模型网关 (Model Gateway)

#### 架构

![模型网关架构](images/fw-arch-03-model-gateway.png)

#### 智能路由

（路由策略详情见上方模型网关架构图中"路由策略矩阵"和"关键设计决策"区域）

#### Fallback 链

![Fallback 链](images/fw-flow-10-fallback-chain.png)

#### 关键设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 网关内核 | LiteLLM Proxy | 提供 100+ 模型统一接入、OpenAI API 兼容、内置 Router/Retry/Fallback/Load Balance/Callback Hook，通过 Hook 注入自定义逻辑不改源码 |
| API 协议 | OpenAI API 兼容 (/v1/chat/completions) | LiteLLM 原生支持，LangChain/LlamaIndex 等框架零成本接入 |
| 模型注册 | LiteLLM YAML 配置 + Admin UI | 新模型接入仅需修改 YAML，不需改代码 |
| 多供应商 | LiteLLM 内置 100+ 模型 + 自研 Adapter 扩展 | 主流模型 LiteLLM 已覆盖，国产特殊模型通过自研 Adapter 扩展 |
| 业务路由 | 自研策略层 (速度/质量/成本/合规) | 通过 LiteLLM Callback Hook 注入，LiteLLM 提供底层 latency/cost/tag 路由 |
| 语义缓存 | 自研 Semantic Cache (非精确匹配) | LiteLLM 仅支持精确匹配 Redis 缓存，语义缓存(命中率 20-35%)自研实现 |
| 安全检测 | 自研 LLM Firewall | Prompt Injection/Jailbreak 检测在策略层实现，进 LiteLLM 前拦截 |
| 限流策略 | Token Bucket，租户+模型双维度 | 自研，LiteLLM 内置限流为全局模式，多租户按 tenant_id 维度需自研 |

### 4.3 RAG 引擎与知识库构建

#### 4.3.1 检索增强生成流水线

![RAG 检索增强生成流水线](images/fw-arch-08-rag-pipeline.png)

检索只是 RAG 的"查询"环节。构建高质量的检索结果，前提是构建高质量的知识库。以下展开知识库构建的全流程。

#### 4.3.2 文档处理管道——从原始文档到结构化知识块

知识库构建的第一步是将原始文档处理为可检索的结构化数据。不同格式的文档需要不同的解析策略：

```
原始文档入库流程:

  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
  │ ① 格式    │ →  │ ② 内容   │ →  │ ③ 智能   │ →  │ ④ 向量化  │ →  │ ⑤ 入库    │
  │   解析    │    │   清洗    │    │   分块    │    │          │    │          │
  └──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
       │               │               │               │               │
   PDF/Word/      去噪/去重/      语义分块/       Embedding      Milvus写入
   Excel/HTML/    格式统一/       重叠窗口/       Model生成       + 原文存
   Markdown/      表格提取        元数据保留      1024维向量      MinIO
   图片(OCR)
```

**各格式的解析方法：**

| 文档格式 | 解析工具 | 关键处理 | 产出 |
|---------|---------|---------|------|
| **PDF** | PyMuPDF / pdfplumber | 提取文本+表格；扫描件走 OCR (PaddleOCR)；保留页码和章节结构 | 纯文本 + 表格 + 元数据 |
| **Word (.docx)** | python-docx | 提取段落+表格+图片；保留标题样式层级 | 结构化文本 |
| **Excel (.xlsx)** | openpyxl / pandas | 按 Sheet 提取；保留表头作为元数据；大表按行切片 | 结构化数据行 |
| **Markdown** | mistletoe / markdown-it | 保留标题层级和代码块语言标记 | 带结构标记的纯文本 |
| **HTML** | BeautifulSoup | 提取 `<article>` / `<main>` 内容；去除导航/广告/脚本 | 纯文本 |
| **图片 (OCR)** | PaddleOCR / Tesseract | 中文识别用 PaddleOCR；保留图片中的表格结构 | 纯文本 |

```python
class DocumentProcessor:
    """文档处理管道——统一入口"""
    
    async def process(self, file_path: str, file_type: str, 
                      tenant_id: str, industry: str) -> ProcessingResult:
        
        # ① 格式解析
        parser = self._get_parser(file_type)
        raw_content = await parser.parse(file_path)
        
        # ② 内容清洗
        cleaner = ContentCleaner()
        cleaned = cleaner.clean(raw_content, rules=[
            RemoveNoiseRule(),       # 去页眉页脚、水印
            NormalizeWhitespaceRule(), # 统一空行和缩进
            ExtractTablesRule(),     # 表格 → Markdown table
            DedupRule(),             # 相邻段落去重
        ])
        
        # ③ 智能分块
        chunker = self._get_chunker(file_type)
        chunks = chunker.split(cleaned)
        
        # ④ 向量化
        embeddings = await self.embedding_service.embed_batch(
            [chunk.text for chunk in chunks],
            model="BAAI/bge-large-zh-v1.5"
        )
        
        # ⑤ 双写入库
        # 向量 → Milvus
        await self.milvus.insert(
            collection=f"{tenant_id}.kb",
            vectors=embeddings,
            metadata=[chunk.to_metadata() for chunk in chunks]
        )
        # 原文 → MinIO
        await self.minio.upload(
            bucket=f"kb-{tenant_id}",
            key=f"{file_path}",
            data=open(file_path, 'rb').read()
        )
        
        return ProcessingResult(
            file_path=file_path,
            chunks_count=len(chunks),
            total_tokens=sum(c.token_count for c in chunks)
        )
```

#### 4.3.3 分块策略详解——不同文档类型的切分逻辑

| 文档类型 | 分块策略 | Chunk Size | Overlap | 特殊处理 |
|---------|---------|------------|---------|---------|
| 技术文档/Markdown | 按标题层级切分 | 512 tokens | 50 tokens | 保留标题层级路径作为 chunk 的 `heading_path` 元数据，检索时可用于上下文扩展 |
| 法律合同 | 按条款切分 | 1024 tokens | 100 tokens | 条款编号索引 (`clause_index`)；条款间交叉引用自动链接 |
| 表格数据 | 按行+上下文切分 | 按表格 | — | 保留表头作为每行的前缀；大表(>50行)按 20 行一批切分，每批附带完整表头 |
| 代码 | AST 语法树切分 | 按函数/类 | 0 | 保留 `import` 和类型定义作为上下文前置；语言标记用于检索过滤 |
| 对话记录 | 按轮次切分 | 按轮次 | 前1轮 | 保留 `role` 和 `timestamp`；连续 3 轮以内保持完整不切 |
| FAQ/问答对 | 按 QA 对切分 | 按对 | 0 | 保留 `question` 和 `answer` 字段分别索引 |

**分块策略的关键原则：**

1. **语义完整性优先于大小限制**——宁可略超 token 上限，也不能把一句话切成两半
2. **元数据不丢失**——每个 chunk 必须携带：来源文档、章节路径、页码、更新时间
3. **上下文可恢复**——检索到 chunk 后，可通过元数据扩展到相邻 chunk

```python
class SemanticChunker:
    """语义感知分块器"""
    
    def split(self, document: Document) -> List[Chunk]:
        chunks = []
        
        if document.type == "markdown":
            # Markdown: 按 ## 标题切分
            sections = self._split_by_headings(document.content)
            for section in sections:
                if self._token_count(section) <= 512:
                    chunks.append(Chunk(
                        text=section["content"],
                        heading_path=section["heading_path"],  # e.g. "§3 > §3.2 > 运输异常"
                        source_file=document.name
                    ))
                else:
                    # 子节还是太大 → 按段落切分，保持 heading_path 不变
                    sub_chunks = self._split_by_paragraph(section["content"], 
                                                          max_tokens=512, overlap=50)
                    for sc in sub_chunks:
                        chunks.append(Chunk(
                            text=sc,
                            heading_path=section["heading_path"],
                            source_file=document.name
                        ))
        
        elif document.type == "pdf_contract":
            # 合同: 按条款编号切分 (如 "第5.3条" / "§5.3")
            clauses = self._split_by_clause_numbers(document.content)
            for clause in clauses:
                chunks.append(Chunk(
                    text=clause["content"],
                    clause_index=clause["number"],
                    source_file=document.name
                ))
        
        elif document.type == "excel":
            # 表格: 每行 + 表头前缀
            table = self._parse_table(document.content)
            header = " | ".join(table["columns"])
            for row in table["rows"]:
                chunks.append(Chunk(
                    text=f"[表头: {header}]\n{row}",
                    table_name=table.get("sheet_name"),
                    row_index=row["index"],
                    source_file=document.name
                ))
        
        return chunks
```

#### 4.3.4 Embedding 生成与向量索引

```python
class EmbeddingPipeline:
    """向量化流水线"""
    
    def __init__(self):
        # 主模型: BGE-large-zh-v1.5 (1024维, 中文SOTA)
        self.model = SentenceTransformer("BAAI/bge-large-zh-v1.5")
        # 备选: M3E-large (768维, 轻量快速)
        self.fallback_model = SentenceTransformer("moka-ai/m3e-large")
    
    async def embed_batch(self, texts: List[str], 
                          model_name: str = "bge-large") -> List[np.ndarray]:
        """批量生成 Embedding"""
        model = self.model if model_name == "bge-large" else self.fallback_model
        
        # BGE 模型需要在 query 前加 instruction prefix
        embeddings = model.encode(
            texts,
            batch_size=32,
            normalize_embeddings=True,    # L2 归一化, 余弦相似度 = 内积
            show_progress_bar=True
        )
        return embeddings.tolist()

# Milvus Collection Schema
collection_schema = {
    "collection_name": f"{tenant_id}.kb",
    "dimension": 1024,                      # BGE-large 输出维度
    "metric_type": "IP",                    # 内积 = 余弦相似度 (已归一化)
    "fields": [
        {"name": "id", "dtype": "INT64", "is_primary": True, "auto_id": True},
        {"name": "embedding", "dtype": "FLOAT_VECTOR", "dim": 1024},
        {"name": "text", "dtype": "VARCHAR", "max_length": 8192},      # chunk 原文
        {"name": "heading_path", "dtype": "VARCHAR", "max_length": 512},
        {"name": "source_file", "dtype": "VARCHAR", "max_length": 256},
        {"name": "chunk_index", "dtype": "INT32"},
        {"name": "industry", "dtype": "VARCHAR", "max_length": 64},
        {"name": "updated_at", "dtype": "INT64"},  # Unix timestamp
    ],
    "index_params": {
        "index_type": "IVF_FLAT",
        "metric_type": "IP",
        "params": {"nlist": 1024}             # 聚类中心数
    }
}
```

#### 4.3.5 知识库质量治理

**构建只是开始，持续治理才是准确率的基础。** 不治理的知识库会随时间退化——过期文档、矛盾信息、低质量内容都会直接拉低 Agent 回答质量。

| 治理维度 | 问题 | 检测方式 | 处理 |
|---------|------|---------|------|
| **时效性** | 文档过期（如 2023 年的 SOP 仍被检索到） | 每个 chunk 记录 `updated_at`；检索时降权超过 6 个月的文档 | 自动标记 `stale`；触发人工审核或自动归档 |
| **矛盾检测** | 同一问题在不同文档中有矛盾回答 | 检索 Top-K 后做 Cross-Encoder 比对；同一实体在不同 chunk 中的描述不一致 | 标记 `conflict`；人工裁决后保留准确版本 |
| **重复内容** | 多次上传同一文档或相似文档 | 入库前计算文档级 Embedding，与已有文档比对相似度 | 相似度 > 0.95 → 跳过；0.85-0.95 → 提示用户确认 |
| **低质量内容** | 纯扫描件、手写体、乱码 | OCR 置信度 < 0.7 → 标记；文本长度 < 10 字符 → 跳过 | 低质量块不索引，但保留原文供人工修复 |
| **覆盖率** | Agent 实际查询 vs 知识库内容覆盖 | 定期分析 Agent 未命中的查询 (Kafka 事件流)，聚类高频未覆盖主题 | 生成"知识库缺口报告" → 人工补充 |

```python
class KnowledgeQualityManager:
    """知识库质量治理"""
    
    async def dedup_check(self, new_doc: Document) -> DedupResult:
        """入库前去重"""
        doc_embedding = await self.embed(new_doc.summary())
        existing = await self.milvus.search(
            collection=f"{tenant_id}.kb_meta",  # 文档级元数据集合
            vector=doc_embedding,
            top_k=1
        )
        if existing and existing[0]["score"] > 0.95:
            return DedupResult(action="skip", reason=f"与 {existing[0]['source_file']} 高度重复")
        if existing and existing[0]["score"] > 0.85:
            return DedupResult(action="warn", reason="可能存在重复，建议人工确认")
        return DedupResult(action="allow")
    
    async def staleness_check(self, tenant_id: str) -> List[StaleChunk]:
        """扫描过期内容"""
        six_months_ago = int((datetime.now() - timedelta(days=180)).timestamp())
        stale = await self.milvus.query(
            collection=f"{tenant_id}.kb",
            filter=f"updated_at < {six_months_ago}"
        )
        return [StaleChunk(**item) for item in stale]
    
    async def gap_analysis(self, tenant_id: str) -> GapReport:
        """知识库缺口分析"""
        # 从 Kafka 消费未命中的查询
        misses = await self.kafka.consume(
            topic=f"{tenant_id}.rag.misses",
            since=timedelta(days=30)
        )
        # 聚类未覆盖主题
        clusters = self._cluster_queries(misses)
        return GapReport(
            top_gaps=clusters[:10],  # Top 10 知识缺口
            recommendation=[f"建议补充 {c['topic']} 相关文档" for c in clusters[:5]]
        )
```

#### 4.3.6 增量更新与版本管理

知识库不是一次性导入就完事的——文档会更新、SOP 会修订、合同会续签。

```
文档更新流程:

  新版本上传
      │
      ▼
  ① 计算新版本 Embedding
      │
      ▼
  ② 在 Milvus 中找到旧版本的所有 chunk
     filter: source_file = "sop-transport.md" AND version = "v2.0"
      │
      ▼
  ③ 批量删除旧 chunk (Milvus delete by expr)
      │
      ▼
  ④ 插入新 chunk (保留相同 source_file 便于追溯)
      │
      ▼
  ⑤ 旧版本原文移到 MinIO archive/ 目录
      │
      ▼
  ⑥ 更新 PG 文档元数据表 (version++, updated_at)
```

```python
class KnowledgeVersionManager:
    """知识库版本管理"""
    
    async def update_document(self, tenant_id: str, file_path: str, 
                              new_version_content: bytes) -> UpdateResult:
        old_version = await self.db.get_document_meta(tenant_id, file_path)
        new_version = old_version["version"] + 1
        
        # ① 删除旧版本向量
        await self.milvus.delete(
            collection=f"{tenant_id}.kb",
            filter=f'source_file == "{file_path}" AND version == {old_version["version"]}'
        )
        
        # ② 处理新版本
        result = await self.doc_processor.process(file_path, new_version_content, 
                                                   tenant_id, version=new_version)
        
        # ③ 归档旧版本原文
        await self.minio.move(
            src=f"kb-{tenant_id}/{file_path}",
            dst=f"kb-{tenant_id}/archive/{file_path}.v{old_version['version']}"
        )
        
        # ④ 更新元数据
        await self.db.execute("""
            UPDATE kb_documents 
            SET version = $1, updated_at = NOW() 
            WHERE tenant_id = $2 AND file_path = $3
        """, new_version, tenant_id, file_path)
        
        return UpdateResult(
            old_version=old_version["version"],
            new_version=new_version,
            chunks_replaced=result.chunks_count
        )
```

#### 4.3.7 行业知识库多租户模型

![行业知识库多租户布局](images/fw-arch-12-knowledge-tenants.png)

每个租户的知识库隔离在独立的 Milvus Collection 中。行业预置知识库（如物流 SOP、金融法规）作为模板导入到新租户时自动复制。

#### 4.3.8 业界开源项目选型——不需要从零写代码

§4.3.2-§4.3.6 中描述的 `DocumentProcessor`、`SemanticChunker`、`KnowledgeQualityManager` 等组件，实际落地时不需要全部自研。知识库构建全流程的每个环节都有成熟开源项目可以直接使用：

```
文档格式解析 → 内容清洗 → 智能分块 → 向量化 → 入库 → 质量治理
      │              │          │         │        │         │
   有现成的      有现成的    有现成的   有现成的  有现成的   需自研
```

| 环节 | 推荐项目 | 说明 | 是否需要自研 |
|------|---------|------|:---:|
| **文档格式解析** | **Unstructured.io** / **MinerU** | Unstructured 支持 20+ 格式（PDF/Word/PPT/Excel/HTML/图片/邮件），一行代码 `partition()` 完成解析；MinerU（OpenDataLab 开源）专注中文 PDF，表格识别和公式提取效果业界最好 | ❌ 直接用 |
| **内容清洗+智能分块** | **LlamaIndex** `IngestionPipeline` / **LangChain** `RecursiveCharacterTextSplitter` | LlamaIndex 一条命令串起解析→清洗→分块→向量化→入库全流程；LangChain 分块器成本最低，支持 Markdown/代码/文本多种模式 | ❌ 直接用 |
| **向量化** | **BGE** (BAAI) / **M3E** / **text2vec** | 下载即用的预训练 Embedding 模型，不需要自己训练。BGE-large-zh-v1.5 是中文 SOTA | ❌ 直接用 |
| **入库+向量索引** | **Milvus** / **Qdrant** | §10.2.3 已有 Helm Chart 部署方案 | ❌ 已部署 |
| **端到端 RAG 平台** | **RagFlow** (infiniflow) / **Dify** | RagFlow 专注深度文档理解，支持复杂 PDF 表格、手写体 OCR；Dify 是可视化 RAG 构建平台，知识库管理全 GUI | ❌ 开箱即用 |
| **质量治理** | — | 时效性检测、矛盾检测、覆盖率缺口分析——这些是平台特有的业务逻辑，开源项目不提供 | ✅ 需自研 |
| **增量更新+版本管理** | — | 文档版本替换、旧版本归档、元数据管理——与多租户和权限耦合，开源项目不提供 | ✅ 需自研 |
| **多租户隔离** | — | Milvus Collection 的租户粒度管理、行业模板复制——平台特有逻辑 | ✅ 需自研 |

**三套推荐组合方案：**

| 方案 | 适用场景 | 具体组成 |
|------|---------|---------|
| **A（轻量，推荐起步）** | 快速验证，文档量 < 1000，团队对 Python 熟悉 | **LlamaIndex** `IngestionPipeline` → **BGE** Embedding → **Milvus**。一套 LlamaIndex 代码串起全流程，不需要挨个集成各环节 |
| **B（中文文档多，质量要求高）** | 大量中文 PDF、合同、SOP 文档，表格多 | **MinerU**（解析 PDF）→ **RagFlow**（深度文档理解，自动识别表格/手写体）→ **BGE** → **Milvus**。MinerU 中文表格识别业界最好，RagFlow 一站式覆盖解析到入库 |
| **C（零代码）** | 非技术人员管理知识库，可视化操作 | **Dify** 知识库功能。GUI 上传文档→自动分块→自动向量化→可视化管理。但定制性差，无法做质量治理。适合内部小规模场景 |

**需要自研的部分归结：**

| 自研组件 | 为什么必须自研 |
|---------|--------------|
| **KnowledgeQualityManager**（§4.3.5） | 时效性/矛盾检测/覆盖面分析的规则是业务逻辑，RagFlow/Dify 不做这个 |
| **KnowledgeVersionManager**（§4.3.6） | 文档版本替换+多租户隔离+行业模板复制，与平台权限体系耦合 |
| **多租户 Collection 管理** | 开源项目的多租户是简单的 key 隔离，平台需要按行业/客户等级的精细隔离策略 |

### 4.4 Prompt 管理中心 (Prompt Hub)

#### 生命周期

![Prompt 生命周期管理与语义缓存](images/fw-flow-11-prompt-cache.png)

#### Prompt 模板示例

```yaml
id: prompt-logistics-cs-v2.3
name: 物流客服系统提示词
version: 2.3.0
base: prompt-customer-service-base-v1.0
industry: logistics
variables:
  - name: company_name
    type: string
    source: tenant_config
  - name: sop_docs
    type: knowledge_base
    source: rag_retrieval
    top_k: 5
model_constraints:
  min_tokens: 512
  temperature: 0.3
evaluation:
  benchmark: logistics_cs_eval_set
  min_score: 0.85
template: |
  你是{{company_name}}的物流智能助手。
  
  处理原则：
  1. 优先从标准作业流程(SOP)中查找答案
  2. 涉及赔偿/投诉，严格按规章制度回复
  3. 无法处理的问题，引导客户联系人工客服
  
  参考知识：
  {{sop_docs}}
```

#### 评估闭环

**评估闭环流程：**

*左路 (发布前):* 新 Prompt 版本上线 → 评估集测试(回归测试) → Score ≥ 0.85? → 是: 发布 / 否: 回退

*右路 (发布后):* 线上运行 → 收集效果指标(采纳率/满意度/转人工率) → Score 下降 > 5%? → 是: 自动告警→人工介入

### 4.5 知识图谱引擎与知识图谱构建

#### 4.5.1 互补定位

与 RAG 的非结构化检索互补，知识图谱解决**结构化关系推理**场景：

- RAG: "仓库 SOP 中入库流程是什么？" → 段落检索 → LLM 回答
- 知识图谱: "客户 A 所有延迟超过 3 天的订单涉及哪些承运商？" → 图遍历 → 精确回答

#### 4.5.2 本体设计——图 Schema 定义

在抽取实体和关系之前，必须先定义本体——这是知识图谱的 schema，决定了哪些实体类型和关系类型是合法的。

**物流行业本体（以运输异常处理场景为例）：**

```
实体类型 (Entity Types):
┌──────────────────────────────────────────────────────────────────┐
│ Customer (客户)          Order (订单)          Carrier (承运商)    │
│ ├─ customer_id           ├─ order_id           ├─ carrier_id      │
│ ├─ name                  ├─ created_at         ├─ name            │
│ └─ tier (VIP/普通)       ├─ status             ├─ sla_promise     │
│                          ├─ priority           └─ penalty_rate    │
│ Shipment (运单)          └─ amount                               │
│ ├─ tracking_number       Warehouse (仓库)       Route (路线)      │
│ ├─ status                ├─ warehouse_id       ├─ route_id        │
│ ├─ origin/destination    ├─ location            ├─ distance        │
│ ├─ estimated_arrival     └─ capacity           ├─ normal_duration │
│ └─ actual_arrival                               └─ risk_factors   │
│ Vehicle (车辆)           Exception (异常)                         │
│ ├─ vehicle_id             ├─ exception_id                         │
│ ├─ type                   ├─ type (delay/damage/loss)             │
│ └─ current_location       ├─ severity (P1/P2/P3)                  │
│                           ├─ root_cause                           │
│                           └─ resolution                           │
└──────────────────────────────────────────────────────────────────┘

关系类型 (Relationship Types):
┌──────────────────────────────────────────────────────────────────┐
│ (Customer) -[:PLACED]-> (Order)                                   │
│ (Order)   -[:CONTAINS]-> (Shipment)                               │
│ (Shipment)-[:ASSIGNED_TO]-> (Carrier)                             │
│ (Shipment)-[:TRANSITS_THROUGH]-> (Warehouse)                      │
│ (Shipment)-[:FOLLOWS]-> (Route)                                  │
│ (Carrier) -[:DISPATCHES]-> (Vehicle)                              │
│ (Shipment)-[:HAS_EXCEPTION]-> (Exception)                         │
│ (Exception)-[:CAUSED_BY]-> (Event)  ← 台风/封路等外部事件         │
│ (Customer) -[:AFFECTED_BY]-> (Exception)                          │
└──────────────────────────────────────────────────────────────────┘
```

**本体 YAML 定义（用于自动化 Schema 管理）：**

```yaml
# ontology-logistics.yaml
industry: logistics
version: "1.0"

entity_types:
  - name: Customer
    key_property: customer_id
    properties:
      - name: name
        type: string
      - name: tier
        type: enum
        values: [VIP, KEY_ACCOUNT, STANDARD]
      - name: industry
        type: string
  
  - name: Shipment
    key_property: tracking_number
    properties:
      - name: status
        type: enum
        values: [in_transit, delayed, delivered, lost, damaged]
      - name: origin
        type: string
      - name: destination
        type: string
      - name: estimated_arrival
        type: datetime
      - name: actual_arrival
        type: datetime
  
  - name: Carrier
    key_property: carrier_id
    properties:
      - name: name
        type: string
      - name: sla_promise
        type: integer  # 承诺时效 (小时)
      - name: penalty_rate
        type: float    # 延迟赔偿率

  - name: Exception
    key_property: exception_id
    properties:
      - name: type
        type: enum
        values: [delay, damage, loss, wrong_address, customs_hold]
      - name: severity
        type: enum
        values: [P1, P2, P3]
      - name: root_cause
        type: string
      - name: resolution
        type: string

relationship_types:
  - name: PLACED
    from: Customer
    to: Order
  - name: CONTAINS
    from: Order
    to: Shipment
  - name: ASSIGNED_TO
    from: Shipment
    to: Carrier
  - name: HAS_EXCEPTION
    from: Shipment
    to: Exception
  - name: CAUSED_BY
    from: Exception
    to: Event
```

#### 4.5.3 实体与关系抽取——构建流水线

知识图谱的构建是一个"抽取-对齐-融合"的流水线，核心依赖 LLM 的 NER+RE 能力：

```
构建流水线:

  数据源                      抽取                         存储
  ┌──────────┐    ┌──────────────────────┐    ┌──────────────────────┐
  │ 非结构化  │    │ ① LLM 实体抽取 (NER)   │    │ Neo4j 知识图谱         │
  │ 文档      │ →  │   从文档中识别实体      │ →  │ (实体节点 + 关系边)    │
  │ (PDF/Word│    │   类型+属性+关系       │    │                      │
  │  /MD)    │    │                      │    │ 同时写入:             │
  └──────────┘    │ ② 实体对齐 (EL)        │    │ · PG entity_index 表  │
                  │   同一实体多种名称      │    │   (快速精确查询)       │
  ┌──────────┐    │   → 归一化到唯一ID     │    │ · Milvus 实体向量索引  │
  │ 结构化    │    │                      │    │   (语义搜索实体)       │
  │ 数据      │ →  │ ③ Schema Mapping     │    └──────────────────────┘
  │ (DB/Excel│    │   结构化数据直接映射    │
  │  /API)   │    │   到本体定义           │
  └──────────┘    └──────────────────────┘
```

**LLM-based 实体关系抽取实现：**

```python
class EntityRelationExtractor:
    """基于 LLM 的实体关系抽取器"""
    
    async def extract_from_document(self, text: str, 
                                     ontology: Ontology) -> ExtractionResult:
        """从非结构化文档中抽取实体和关系"""
        
        prompt = f"""
你是一个知识图谱构建助手。根据给定的本体定义，从以下文档中抽取实体和关系。

## 本体定义
实体类型: {[e.name for e in ontology.entity_types]}
关系类型: {[r.name for r in ontology.relationship_types]}

## 抽取规则
1. 只抽取本体中已定义的实体类型和关系类型
2. 每个实体必须包含 key_property (用于实体对齐)
3. 关系的 from 和 to 必须是已抽取的实体
4. 同一实体在文档中多次出现时，只抽取一次 (合并属性)
5. 无法确定的值留空，不要编造

## 文档内容
{text[:8000]}  # 单次最多处理 8000 字符

## 输出格式 (JSON)
{{
  "entities": [
    {{
      "type": "Shipment",
      "properties": {{
        "tracking_number": "SF1234567890",
        "status": "delayed",
        "origin": "上海",
        "destination": "北京",
        "estimated_arrival": "2026-05-15T10:00:00"
      }},
      "source_text": "运单SF1234567890从上海发往北京，原定5月15日10点到达",
      "confidence": 0.95
    }}
  ],
  "relationships": [
    {{
      "type": "HAS_EXCEPTION",
      "from": {{"type": "Shipment", "key": "SF1234567890"}},
      "to": {{"type": "Exception", "key": "EXC-001"}},
      "properties": {{}},
      "source_text": "该运单因台风影响延迟",
      "confidence": 0.92
    }}
  ]
}}
"""
        response = await self.model_gateway.chat(
            model="claude-sonnet-4-6",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.1,  # 抽取任务需要低温度
            response_format={"type": "json_object"}
        )
        
        return ExtractionResult.parse(response)
```

#### 4.5.4 实体对齐——同一实体的多种表述归一化

```
非结构化文档中同一实体的不同表述:

  "顺丰速运" / "顺丰" / "SF Express" / "顺丰快递"
  "SF1234567890" / "SF123456" / "运单SF123"
  "台风艾云尼" / "台风"艾云尼"" / "第3号台风"

     ↓  实体对齐 (Entity Linking)

  统一 ID: carrier_001 (顺丰速运)
  统一 ID: shipment_SF1234567890
  统一 ID: event_typhoon_aiyunn_20260514
```

```python
class EntityLinker:
    """实体对齐器——将多种表述归一化到唯一实体ID"""
    
    async def link(self, entity: ExtractedEntity, 
                   existing_entities: EntityIndex) -> LinkResult:
        """
        对齐策略 (按优先级):
        ① key_property 精确匹配 (如 tracking_number = "SF1234567890")
        ② 名称模糊匹配 + 类型相同
        ③ Embedding 语义匹配 (如 "顺丰" vs "顺丰速运")
        ④ 无匹配 → 新建实体 (分配新 ID)
        """
        
        # 策略①: key_property 精确匹配——最高置信度
        if entity.key_property and entity.key_property in existing_entities:
            existing = existing_entities[entity.key_property]
            # 合并属性
            merged = self._merge_properties(existing, entity)
            return LinkResult(
                action="merge",
                entity_id=existing.id,
                confidence=1.0,
                merged_properties=merged
            )
        
        # 策略②: 名称 + 类型模糊匹配
        candidates = existing_entities.search(
            name=entity.name,
            entity_type=entity.type,
            fuzzy=True  # Levenshtein distance < 3
        )
        if candidates:
            best = candidates[0]
            if best.similarity > 0.9:
                return LinkResult(action="merge", entity_id=best.id, confidence=best.similarity)
        
        # 策略③: Embedding 语义匹配
        entity_embedding = await self.embed(entity.name)
        semantic_matches = existing_entities.vector_search(
            embedding=entity_embedding,
            entity_type=entity.type,
            top_k=1
        )
        if semantic_matches and semantic_matches[0]["score"] > 0.85:
            return LinkResult(
                action="merge", 
                entity_id=semantic_matches[0]["entity_id"],
                confidence=semantic_matches[0]["score"]
            )
        
        # 策略④: 无匹配 → 新建
        new_id = self._generate_entity_id(entity)
        return LinkResult(action="create", entity_id=new_id, confidence=0.5)
```

#### 4.5.5 图构建与存储

```cypher
-- Neo4j 物流知识图谱构建示例

// 创建实体节点
CREATE (c:Customer {id: 'CUST-001', name: 'XX电子', tier: 'KEY_ACCOUNT'})
CREATE (s:Shipment {
    id: 'SF1234567890',
    status: 'delayed',
    origin: '上海',
    destination: '北京',
    estimated_arrival: datetime('2026-05-15T10:00:00'),
    actual_arrival: null
})
CREATE (cr:Carrier {id: 'CARRIER-SF', name: '顺丰速运', sla_promise: 24, penalty_rate: 0.3})
CREATE (e:Exception {
    id: 'EXC-001',
    type: 'delay',
    severity: 'P2',
    root_cause: '台风艾云尼影响杭州段封路',
    detected_at: datetime('2026-05-14T18:00:00')
})
CREATE (ev:Event {id: 'EVT-001', name: '台风艾云尼', category: 'weather', start_date: date('2026-05-14')})

// 创建关系
CREATE (c)-[:PLACED]->(o:Order {id: 'ORD-001', created_at: datetime('2026-05-13')})
CREATE (o)-[:CONTAINS]->(s)
CREATE (s)-[:ASSIGNED_TO]->(cr)
CREATE (s)-[:HAS_EXCEPTION]->(e)
CREATE (e)-[:CAUSED_BY]->(ev)

// 索引
CREATE INDEX shipment_id FOR (s:Shipment) ON (s.id)
CREATE INDEX exception_type FOR (e:Exception) ON (e.type)
CREATE FULLTEXT INDEX entity_name FOR (n:Customer|Carrier) ON EACH [n.name]
```

#### 4.5.6 混合检索——RAG + 知识图谱联合查询

```python
class HybridRetriever:
    """混合检索: 向量检索 (RAG) + 图检索 (知识图谱) + 关键词检索 (ES) 三路融合"""
    
    async def hybrid_search(self, query: str, tenant_id: str, 
                            top_k: int = 5) -> HybridResult:
        
        # 并行执行三路检索
        vectors, graph, keywords = await asyncio.gather(
            self._vector_search(query, tenant_id, top_k),   # Milvus
            self._graph_search(query, tenant_id),           # Neo4j
            self._keyword_search(query, tenant_id, top_k)   # Elasticsearch
        )
        
        # 融合排序
        all_results = []
        
        for item in vectors:
            all_results.append(ScoredItem(
                source="vector", score=item["score"] * 0.5,  # 权重 0.5
                content=item["text"], metadata=item["metadata"]
            ))
        
        for item in graph:
            all_results.append(ScoredItem(
                source="graph", score=item["score"] * 0.3,  # 权重 0.3
                content=self._graph_to_text(item),           # 图结果转自然语言
                metadata={"type": "graph", "query": item["cypher"]}
            ))
        
        for item in keywords:
            all_results.append(ScoredItem(
                source="keyword", score=item["score"] * 0.2,  # 权重 0.2
                content=item["text"], metadata=item["metadata"]
            ))
        
        # 去重 + Rerank
        deduped = self._deduplicate(all_results)
        reranked = await self.reranker.rerank(query, deduped, top_k)
        
        return HybridResult(items=reranked)
    
    async def _graph_search(self, query: str, tenant_id: str) -> list:
        """图检索——LLM 将自然语言转为 Cypher 查询"""
        
        # 先查实体索引
        entities = await self.entity_index.search(query)
        
        if not entities:
            return []
        
        # 用找到的实体构建 Cypher 查询
        cypher = """
        MATCH (s:Shipment {id: $tracking_number})-[r]->(n)
        RETURN s, type(r) as relation, n
        LIMIT 10
        """
        
        result = await self.neo4j.run(cypher, 
            tracking_number=entities[0]["id"])
        
        return [
            {"score": 1.0, "cypher": cypher, 
             "data": dict(record)}
            for record in result
        ]
```

#### 4.5.7 图谱维护与质量保障

| 维护维度 | 方法 | 频率 |
|---------|------|:---:|
| **新增实体/关系** | 文档入库时自动触发 NER+RE 抽取；结构化数据通过定时任务批量导入 | 实时 / 每日 |
| **实体属性更新** | 运单状态变更、车辆位置更新通过 Kafka 事件流实时更新 Neo4j 节点属性 | 实时 |
| **过期关系清理** | 已完成订单的关系（如 `IN_TRANSIT`）保留为历史边（`historical: true`），用于趋势分析但不参与实时推理 | 每周 |
| **一致性校验** | 定期检查：同一 tracking_number 不应同时关联两个承运商；运单状态为 delivered 则不应有 active exception | 每日 |
| **人工审核** | LLM 抽取的实体中，confidence < 0.8 的进入人工审核队列；审核通过的写入 Neo4j，不通过的丢弃或人工修正 | 按需 |

```python
class GraphMaintainer:
    """知识图谱维护器"""
    
    async def consistency_check(self, tenant_id: str) -> ConsistencyReport:
        """一致性校验"""
        issues = []
        
        # 规则1: 已签收的运单不应有活跃异常
        result = await self.neo4j.run("""
            MATCH (s:Shipment {status: 'delivered'})-[r:HAS_EXCEPTION]->(e:Exception)
            WHERE e.resolution IS NULL
            RETURN s.id, e.id
        """)
        for record in result:
            issues.append(ConsistencyIssue(
                rule="delivered_with_active_exception",
                entity=record["s.id"],
                detail=f"已签收运单存在未解决的异常 {record['e.id']}"
            ))
        
        # 规则2: 一个运单不应同时分配给多个承运商
        result = await self.neo4j.run("""
            MATCH (s:Shipment)-[:ASSIGNED_TO]->(c:Carrier)
            WITH s, count(c) as carrier_count
            WHERE carrier_count > 1
            RETURN s.id, carrier_count
        """)
        for record in result:
            issues.append(ConsistencyIssue(
                rule="multiple_carriers",
                entity=record["s.id"],
                detail=f"运单分配给 {record['carrier_count']} 个承运商"
            ))
        
        return ConsistencyReport(
            total_issues=len(issues),
            issues=issues,
            action="warn" if issues else "pass"
        )
    
    async def update_from_event(self, event: KafkaEvent):
        """从 Kafka 事件流实时更新图谱"""
        if event.type == "shipment.status_changed":
            await self.neo4j.run("""
                MATCH (s:Shipment {id: $tracking_number})
                SET s.status = $new_status, s.updated_at = datetime()
            """, tracking_number=event.tracking_number, 
                new_status=event.new_status)
        
        elif event.type == "exception.resolved":
            await self.neo4j.run("""
                MATCH (e:Exception {id: $exception_id})
                SET e.resolution = $resolution, e.resolved_at = datetime()
            """, exception_id=event.exception_id, 
                resolution=event.resolution)
```

#### 4.5.8 业界开源项目选型——不需要从零写抽取代码

§4.5.3-§4.5.7 中描述的 `EntityRelationExtractor`、`EntityLinker`、`GraphMaintainer` 等组件，实际落地时不需要全部自研。知识图谱构建的每个环节同样有成熟开源项目：

```
实体抽取 (NER) → 关系抽取 (RE) → 实体对齐 (EL) → 知识融合 → 图存储
      │               │              │            │          │
   有现成的        有现成的        有现成的      有现成的   有现成的
```

| 环节 | 推荐项目 | 说明 | 是否需要自研 |
|------|---------|------|:---:|
| **端到端图谱构建** | **Microsoft GraphRAG** | **强烈推荐。** 2024年7月开源，20k+ stars。一条命令从原始文档自动构建知识图谱：实体抽取→关系抽取→社区检测→层级摘要。不需要手写 NER/RE 代码 | ❌ 直接用 |
| **实体抽取 (NER)** | **spaCy** / **DeepKE** | spaCy 适合英文 NER；DeepKE（浙江大学）专注中文知识抽取，支持实体/关系/属性/事件四类抽取，预训练模型开箱即用 | ❌ 直接用 |
| **关系抽取 (RE)** | **DeepKE** / **REBEL** | DeepKE 预训练关系抽取模型；REBEL 是端到端关系抽取（Seq2Seq），适合非结构化文本 | ❌ 直接用 |
| **知识图谱 Schema + 全生命周期** | **OpenSPG** (蚂蚁集团) | 2024年开源。你方案中 §4.5.2 的本体 YAML 直接对标 OpenSPG 的 Schema 定义格式。自带 Schema 管理→实体链接→知识融合→规则推理。中文场景企业级首选 | ❌ 直接用 |
| **NL→Cypher 图查询转换** | **LlamaIndex** `KnowledgeGraphIndex` / **LangChain** `GraphCypherQAChain` | 不需要手写 Cypher——自然语言问题自动转为图查询语句。方案 §4.5.6 混合检索中"LLM 自然语言→Cypher"即用此实现 | ❌ 直接用 |
| **图存储** | **Neo4j** | §10.2.3 已有 Helm Chart 部署方案 | ❌ 已部署 |
| **本体设计 (Schema)** | — | 物流/金融/制造每个行业有自己的实体和关系定义，OpenSPG 提供 Schema 框架，但行业本体内容需要领域专家设计 | ⚠️ 行业本体需领域专家 |
| **图谱一致性校验** | — | "已签收运单不应有活跃异常"这类业务规则是与行业本体耦合的，开源项目不提供 | ✅ 需自研 |
| **Kafka 事件流实时更新图谱** | — | 运单状态变更→实时更新 Neo4j 节点属性，是平台特有的实时数据管道 | ✅ 需自研 |

**三套推荐组合方案：**

| 方案 | 适用场景 | 具体组成 |
|------|---------|---------|
| **A（轻量，推荐起步）** | 从文档构建图谱，快速验证 | **Microsoft GraphRAG** → **Neo4j**。一条命令从文档构建图谱，覆盖实体抽取+关系抽取+社区摘要。只需准备文档，不需要手写任何抽取代码 |
| **B（中文场景，企业级）** | 中文文档为主，需要 Schema 管理和知识推理 | **OpenSPG**（Schema 定义+知识抽取+融合）→ **Neo4j**（存储）→ **LlamaIndex** `KnowledgeGraphIndex`（检索）。蚂蚁开源，中文支持好，自带本体管理+知识推理 |
| **C（仅需实体识别，不求全图谱）** | 只做 NER，不做复杂关系 | **DeepKE** → **Neo4j**。浙江大学开源，中文 NER+RE 预训练模型直接可用。适合起步阶段先识别关键实体，后续再扩展到关系 |

**对方案 §4.5.3 和 §4.5.4 的落地调整：**

方案中 `EntityRelationExtractor`（LLM-based NER+RE）和 `EntityLinker`（实体对齐）的代码是**架构设计层面的实现原理说明**，实际落地时：

| 方案中写的 | 实际落地用什么 | 说明 |
|-----------|-------------|------|
| `EntityRelationExtractor.extract_from_document()` | **GraphRAG** 一条命令替代 | GraphRAG 内部已实现 LLM-based NER+RE，且做了去重和社区检测 |
| `EntityLinker.link()` | **OpenSPG** 的 `EntityLinker` 或 **GraphRAG** 内置实体消歧 | 开源项目已实现实体对齐，不需要自己写策略 |
| LLM Prompt（NER+RE 模板） | GraphRAG/OpenSPG 内置 | 不需要自己维护 Prompt，开源项目已调优 |
| 仍需自研的部分 | `GraphMaintainer`（一致性校验+Kafka事件实时更新） | 这两块是平台特有业务逻辑 |

### 4.6 MLOps 流水线（Agent 导向）

传统 MLOps 是训练密集型（数据→训练→评估→部署），Agent MLOps 是**迭代密集型**（Prompt→评估→发布→监控→反馈）。

![Agent MLOps 流水线](images/fw-arch-15-mlops-pipeline.png)

**评估维度：**
- 准确性: 答案正确率、引用准确率
- 安全性: 有害内容率、越狱成功率
- 效率: 平均步数、Token 消耗
- 体验: 用户满意度、任务完成率
- 一致性: 同 Query 多次结果一致性

### 4.7 语义缓存层

**语义缓存决策链：**

1. 请求流入 → 精确匹配缓存? → Yes: 直接返回 (~5% 命中率)
2. → No → 语义相似度计算 (Embedding Cosine Similarity)
3. Similarity > 0.95 → 返回缓存结果 + 标记 cached
4. Similarity > 0.85 → 返回缓存结果 + 追加差异补充
5. Similarity < 0.85 → 调用 LLM + 结果写入缓存

典型命中率: 20-35% (企业场景同质化问题占比高)

---

## 5. Agent 平台层

### 5.1 定位

Agent 平台层是产品的**核心引擎**：让 Agent 被构建、运行、管理和复用。

### 5.2 Agent 生命周期

![Agent 生命周期状态机](images/fw-arch-20-agent-lifecycle.png)

| 阶段 | 触发者 | 关键行为 | 产出物 |
|------|--------|---------|--------|
| **Draft** | 构建者 | 配置 Agent 定义、选择技能、编写 Prompt | Agent 草稿 |
| **Testing** | 系统自动 | 评估集自动测试、回归测试 | 评估报告 |
| **Review** | 审核者 | 人工审核评估结果、审批发布 | 审批记录 |
| **Published** | 系统 | 版本锁定、镜像打包 | Agent 版本快照 |
| **Running** | 运维/系统 | 部署、监控、自动扩缩 | 运行实例 |

### 5.3 Agent 构建方式（三级）

| 方式 | 目标用户 | 实现 | 覆盖预期 |
|------|---------|------|---------|
| **对话式构建 (No-Code)** | 业务人员 | "帮我创建一个能回答仓库 SOP 的助手" → LLM 自动选技能、配 Prompt、建议测试 | 30% |
| **可视化编排 (Low-Code)** | 业务分析师 | 拖拽式工作流 + 预置模板定制 | 50% |
| **Pro-Code** | 开发者 | Python/JS SDK + CLI，完全控制 | 20% |

### 5.4 Agent 定义 DSL

```yaml
apiVersion: agent.platform/v1
kind: Agent
metadata:
  name: logistics-exception-handler
  version: 2.1.0
  industry: logistics
spec:
  model:
    primary: claude-opus-4-7
    fallback: deepseek-v4
    temperature: 0.3
    max_tokens: 4096
  
  prompt:
    ref: prompt-logistics-exception-v2
  
  skills:
    - ref: skill-track-query
      required: true
    - ref: skill-abnormal-detection
      required: true
    - ref: skill-customer-notify
      required: false
  
  knowledge:
    - ref: kb-logistics-sop
      retrieval_top_k: 5
  
  memory:
    short_term: { max_turns: 20, ttl: 3600 }
    long_term: { enabled: true, scope: tenant }
  
  execution:
    max_steps: 15
    timeout: 120s
    
    human_approval:
      enabled: true
      triggers:
        - action: cancel_order
        - amount_gt: 10000
        - confidence_lt: 0.8
  
  evaluation:
    dataset: eval-logistics-exception
    min_score: 0.85
```

### 5.5 编排引擎

#### 编排策略层次

| 策略 | 场景 | 示例 |
|------|------|------|
| **Simple** | 单步对话，无工具调用 | 问答 |
| **Chain** | 顺序管道，固定流程 | 入库六步流程 |
| **Router** | 条件分支，规则/LLM 判定 | 异常分级路由 |
| **Graph** | 复杂 DAG，多路并行+汇聚 | 多 Agent 协作 |

#### 多 Agent 协作模式

1. **Sequential**: [Agent A] → [Agent B] → [Agent C] (客服→路由→通知)
2. **Router**: 根据行业/意图分发到对应 Agent
3. **Hierarchical**: Supervisor Agent 分配子任务+汇总结果
4. **Mesh**: 复杂跨部门流程网状协作
5. **Debate**: 多 Agent 交叉验证 (风险评估、合规审查)

#### 协作协议

| 协议 | 用途 | 优先级 |
|------|------|--------|
| **A2A** | Agent 间任务委托和状态同步 | 优先支持 |
| **MCP** | Agent 调用外部 Tool/Skill | 优先支持 |
| **内部 gRPC** | 平台内 Agent 间高性能通信 | 自研 |
| **Webhook** | 结果推送到外部系统 | 标准 HTTP |

### 5.6 技能市场

**技能市场生态：**

| 来源 | 类型 | 示例 |
|------|------|------|
| **平台官方** | 基础技能 | 运单查询、天气查询、短信通知、邮件发送 |
| **ISV/伙伴** | 行业技能 | 报关、授信审批、质检规则、合规稽核 |
| **社区/客户** | 定制技能 | 内部 SOP、特定 API 对接 |

发布流程: 开发 → 测试 → 审核 → 上架 → 版本管理
计费模式: 免费基础 / 按调用付费 / 按月订阅

### 5.7 分层记忆系统

![分层记忆系统](images/fw-arch-13-memory-system.png)

### 5.8 评估监控体系

**离线评估（发布前）**：
- LLM-as-Judge：准确性、有用性、安全性评分
- 规则断言：格式校验、关键字包含、JSON 有效性、引用完整性
- 人工标注：金标数据、边角案例、对抗样本

**在线监控（发布后）**：
- 实时指标：采纳率、转人工率、平均耗时、Token 效率
- 异常检测：指标突降、幻觉率飙升、P99 延迟恶化
- 反馈回路：👍👎 评分、用户评论、纠错数据

---

## 6. 行业解决方案层

### 6.1 行业包 (Industry Pack) 模型

行业包 = 行业平台的最小交付单元，包含：

**Industry Pack: logistics-v3.2 包含：**
- 预置 Agent 模板: 异常处理、路径优化、仓储问答、客户服务
- 行业知识库: 物流 SOP、报关规则、运价表、承运商 DB
- 行业技能: 运单查询、时效预测、异常检测、路线推荐
- 行业连接器: TMS/WMS/OMS 对接
- Prompt 模板: 物流场景专用 Prompt
- 评估集: 物流评测专用用例
- 行业数据模型 (Ontology): 实体/关系/术语体系

### 6.2 行业接入流程

| 阶段 | 周期 | 任务 |
|------|------|------|
| **Phase 1: 行业调研** | 2-4 周 | Know-how 梳理、竞品对标、本体构建、Top 10 场景识别 |
| **Phase 2: 行业包构建** | 4-8 周 | 知识库构建、Agent 模板开发、技能开发、连接器开发、评估集构建 |
| **Phase 3: 伙伴联合验证** | 4-6 周 | 1-2 家灯塔客户联合打磨、真实场景测试调优、案例产出 |
| **Phase 4: 正式发布** | — | 上架技能市场、Landing Page/Demo、联合推广、运营反馈 |

### 6.3 首批行业 Agent 矩阵

**物流行业**：

| 领域 | Agent | 核心能力 |
|------|-------|---------|
| 运输管理 | 路径优化 Agent | 实时路况+费率、多目标优化、承运商推荐 |
| 运输管理 | 异常处理 Agent | 延迟自动检测、根因分析、升级策略、客户通知 |
| 仓储管理 | 库存巡检 Agent | 库存健康检查、补货建议、效期预警 |
| 仓储管理 | 波次协调 Agent | 波次前检查、问题预警、修复方案 |
| 客户服务 | 智能客服 Agent | 运单查询、异常处理引导、索赔引导 |
| 伙伴结算 | 对账结算 Agent | 运费自动核算、异常差异识别、付款建议 |
| 伙伴结算 | 合规审查 Agent | 报关合规检查、证件有效期、法规变更预警 |

**金融行业**：

| Agent | 核心能力 |
|-------|---------|
| 合规审查 Agent | 监管条例检索、材料合规检查、审查报告生成 |
| 风控评估 Agent | 企业风险画像、异常交易检测、风险评级建议 |
| 智能客服 Agent | 产品咨询、业务办理引导、合规话术 |
| 报告生成 Agent | 尽调报告、授信报告、监管报送 |

### 6.4 多租户隔离

| Tier | 模式 | 隔离度 | 成本 | 适用 |
|------|------|--------|------|------|
| **Tier 1** | 共享 SaaS (Schema 级隔离) | 逻辑隔离 | 低 | <500 用户 |
| **Tier 2** | 专属实例 (K8s Namespace + 独立 DB) | 资源隔离 | 中 | 500-5000 用户 |
| **Tier 3** | 私有化部署 (完全物理隔离) | 物理隔离 | 高 | 无上限 |

### 6.5 连接器生态

| 层级 | 内容 |
|------|------|
| **Layer 1: 行业标准连接器** | 物流(TMS/WMS/OMS)、金融(核心银行/征信/反洗钱)、制造(ERP/MES/SCADA) |
| **Layer 2: 通用连接器** | 数据库(MySQL/PG/Oracle)、文件(SFTP/S3)、消息(Kafka/RabbitMQ)、协作(飞书/钉钉/企微) |
| **Layer 3: 自定义连接器** | 通过 Connector SDK 自行开发，可上架技能市场 |

---

## 7. 平台横切能力

### 7.1 安全合规体系总览

![AI 安全护栏 Guardrails 五层防护](images/fw-arch-16-security-layers.png)

安全体系覆盖五个层次，外加一条贯穿的审计追溯线：

| 层次 | 职责 | 核心组件 |
|------|------|---------|
| **L1: 基础设施安全** | 镜像扫描、漏洞管理、配置基线、入侵检测 | Trivy + Falco + CIS Benchmark |
| **L2: 网络安全** | WAF、DDoS 防护、IP 黑白名单、VPC 隔离 | Higress WAF + K8s NetworkPolicy |
| **L3: 应用安全** | 身份认证、权限控制、API 安全 | Keycloak + OpenFGA + 自研 API 安全层 |
| **L4: AI 安全** | Prompt Injection 防御、Jailbreak 检测、内容安全、幻觉检测 | 自研 LLM Firewall |
| **L5: 数据安全** | 传输加密、存储加密、PII 脱敏、数据分类分级 | TLS 1.3 + AES-256 + KMS |
| **审计追溯** | 全链路审计日志、不可篡改、合规保留 7 年 | PG audit_log + Kafka + MinIO 归档 |

### 7.2 身份认证体系

#### 7.2.1 认证架构

```
用户/开发者
    │
    ├── Web UI → OIDC (Keycloak) → JWT Token
    │
    ├── API 调用 → API Key / OAuth 2.0 Client Credentials
    │
    ├── SDK/CLI → Personal Access Token (PAT)
    │
    └── Agent-to-Agent → mTLS (双向 TLS 证书认证)
```

#### 7.2.2 认证方式矩阵

| 认证方式 | 适用场景 | Token 有效期 | 刷新机制 |
|---------|---------|:---:|------|
| **OIDC (Keycloak)** | Web 管理后台、Agent Playground | Access: 15min, Refresh: 8h | Refresh Token 自动续期 |
| **OAuth 2.0 Client Credentials** | 企业 Java 后端 → Agent 服务 | 1h | client_secret 换取新 Token |
| **API Key** | ISV 伙伴集成、CI/CD 自动化 | 无固定（可配置） | 手动轮换 |
| **Personal Access Token** | 开发者 CLI 调试 | 90 天 | 手动创建新 Token |
| **mTLS** | Agent 间通信 (A2A 协议) | 证书有效期 1 年 | 证书自动续签 |

#### 7.2.3 Keycloak 集成配置

```yaml
# Keycloak Realm 配置
realm: ai-platform
clients:
  - client_id: admin-ui
    type: public
    redirect_uris: ["https://admin.ai-platform.com/*"]
    
  - client_id: agent-runtime
    type: confidential
    service_accounts_enabled: true
    
  - client_id: java-backend
    type: confidential
    authorization_services_enabled: true

identity_providers:
  - alias: company-sso
    provider_id: saml           # 对接企业已有 SSO
  - alias: ldap
    provider_id: ldap           # 对接企业 LDAP/AD

roles:
  - platform_admin              # 平台管理员
  - tenant_admin                # 租户管理员
  - agent_developer             # Agent 开发者
  - agent_operator              # Agent 运维
  - skill_developer             # 技能开发者
  - auditor                     # 审计员（只读）
```

### 7.3 权限控制模型

#### 7.3.1 三维权限模型 (RBAC + ABAC + ReBAC)

```
┌─────────────────────────────────────────────────────────────────┐
│                    三维权限模型                                   │
│                                                                 │
│  RBAC (角色)              ABAC (属性)            ReBAC (关系)    │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐    │
│  │ platform_admin  │  │ tenant_id      │  │ 部门层级关系     │    │
│  │ tenant_admin    │  │ user_tier      │  │ 项目归属关系     │    │
│  │ agent_developer │  │ department     │  │ Agent 所有权     │    │
│  │ skill_developer │  │ clearance_level│  │ 审批委托关系     │    │
│  │ agent_operator  │  │ ip_range       │  │ 技能授权关系     │    │
│  │ auditor         │  │ time_window    │  │                 │    │
│  └────────────────┘  └────────────────┘  └────────────────┘    │
│                                                                 │
│  判断逻辑: allowed = RBAC(role, action, resource)               │
│                    AND ABAC(user_attrs, env_attrs, resource_attrs)│
│                    AND ReBAC(user, relation, resource)           │
└─────────────────────────────────────────────────────────────────┘
```

#### 7.3.2 OpenFGA 权限模型

```yaml
# OpenFGA Authorization Model
schema_version: "1.1"

type user

type tenant
  relations:
    define admin: [user]
    define member: [user]
    define agent_developer: [user]
    define skill_developer: [user]
    define auditor: [user]

type agent
  relations:
    define owner: [tenant]
    define viewer: [user, tenant#member]
    define editor: [user, tenant#agent_developer]
    define executor: [user, tenant#member]
    define approver: [user]

type skill
  relations:
    define owner: [tenant]
    define user: [tenant#member, agent#executor]
    define manager: [user, tenant#skill_developer]

type knowledge_base
  relations:
    define owner: [tenant]
    define reader: [tenant#member, agent#executor]
    define editor: [user, tenant#admin]

type session
  relations:
    define owner: [user]
    define viewer: [tenant#admin, tenant#auditor]
```

#### 7.3.3 权限检查示例

```python
# 检查: 用户能否运行 Agent？
async def can_execute_agent(user_id: str, agent_name: str, tenant_id: str) -> bool:
    """三维权限检查"""
    
    # RBAC: 用户在该租户下是否有 member 角色
    has_role = await openfga.check(
        user=f"user:{user_id}",
        relation="member",
        object=f"tenant:{tenant_id}"
    )
    if not has_role:
        return False
    
    # ABAC: 用户层级 + 时间段限制
    user = await db.get_user(user_id)
    if user.clearance_level == "restricted":
        now = datetime.now()
        if now.hour < 8 or now.hour > 18:  # 限制用户只能在工作时间操作
            return False
    
    # ReBAC: 该 Agent 是否对该租户成员开放
    can_exec = await openfga.check(
        user=f"user:{user_id}",
        relation="executor",
        object=f"agent:{agent_name}"
    )
    
    return can_exec

# 检查: 用户能否编辑 Prompt？
async def can_edit_prompt(user_id: str, prompt_id: str, tenant_id: str) -> bool:
    return await openfga.check(
        user=f"user:{user_id}",
        relation="editor",
        object=f"agent:{prompt_id.split('-')[0]}"  # Prompt 继承 Agent 的编辑权限
    )
```

#### 7.3.4 权限矩阵速查

| 操作 | platform_admin | tenant_admin | agent_developer | agent_operator | skill_developer | auditor |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| 创建租户 | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| 管理租户成员 | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| 创建/编辑 Agent | ✅ | ✅ | ✅ (本租户) | ❌ | ❌ | ❌ |
| 部署/下线 Agent | ✅ | ✅ | ❌ | ✅ (本租户) | ❌ | ❌ |
| 运行 Agent | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| 创建/编辑 Skill | ✅ | ✅ | ❌ | ❌ | ✅ (本租户) | ❌ |
| 审核 Skill | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| 编辑 Prompt | ✅ | ✅ | ✅ (本租户) | ❌ | ❌ | ❌ |
| 查看审计日志 | ✅ | ✅ (本租户) | ❌ | ❌ | ❌ | ✅ |
| 查看计费 | ✅ | ✅ (本租户) | ❌ | ❌ | ❌ | ✅ |
| 审批 HITL | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| API Key 管理 | ✅ | ✅ (本租户) | ✅ (本人) | ✅ (本人) | ✅ (本人) | ❌ |

### 7.4 API 安全

#### 7.4.1 防护层次

```
外部请求
    │
    ▼
┌─────────────────────────────────────────────────────┐
│ Layer 1: Higress Gateway                             │
│   · DDoS 防护 (连接数限流)                            │
│   · IP 黑白名单                                      │
│   · WAF (SQL Injection / XSS / CSRF)                 │
│   · TLS 1.3 终结                                     │
│   · Wasm 插件: Prompt Injection 预检                  │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│ Layer 2: API 安全中间件 (自研)                        │
│   · JWT / API Key 验证                               │
│   · 权限检查 (OpenFGA)                               │
│   · 速率限制 (Token Bucket, 租户+接口双维度)          │
│   · 请求体大小限制 (10MB)                             │
│   · 响应数据脱敏 (PII 自动打码)                        │
└──────────────────────┬──────────────────────────────┘
                       │
                       ▼
                  业务服务
```

#### 7.4.2 速率限制策略

```yaml
# 限流配置
rate_limits:
  # 租户级
  tenant_default:
    requests_per_second: 100
    burst: 200
  
  # 接口级 (优先级高于租户级)
  endpoints:
    - path: /agents/*/run
      requests_per_second: 20      # Agent 推理接口更严格的限制
      burst: 30
    
    - path: /agents/*/run-async
      requests_per_second: 50
    
    - path: /skills/register
      requests_per_second: 10
    
    - path: /admin/*
      requests_per_second: 30
  
  # 模型调用级
  model_calls:
    per_tenant_per_minute: 1000
    per_agent_per_minute: 100
```

#### 7.4.3 API Key 安全管理

```python
# API Key 生成与验证
class ApiKeyManager:
    
    def generate_key(self, tenant_id: str, user_id: str, scopes: list[str]) -> dict:
        """生成 API Key: sk-{prefix}-{random}"""
        prefix = "sk-aiap"
        key = f"{prefix}-{secrets.token_urlsafe(32)}"
        hashed = hashlib.sha256(key.encode()).hexdigest()
        
        # 仅存哈希
        await self.db.execute("""
            INSERT INTO api_keys (key_hash, tenant_id, user_id, scopes, created_at)
            VALUES ($1, $2, $3, $4, NOW())
        """, hashed, tenant_id, user_id, scopes)
        
        return {"key": key, "scopes": scopes, "note": "仅显示一次，请妥善保存"}
    
    def validate(self, key: str) -> dict | None:
        """验证 API Key"""
        hashed = hashlib.sha256(key.encode()).hexdigest()
        row = await self.db.fetchrow("""
            SELECT tenant_id, user_id, scopes 
            FROM api_keys 
            WHERE key_hash = $1 AND revoked = FALSE
        """, hashed)
        
        if not row:
            return None
        
        # 记录最后使用时间
        await self.db.execute("""
            UPDATE api_keys SET last_used_at = NOW() WHERE key_hash = $1
        """, hashed)
        
        return {"tenant_id": row["tenant_id"], "user_id": row["user_id"], "scopes": row["scopes"]}
    
    def rotate_key(self, old_key: str) -> dict:
        """轮换: 吊销旧 Key + 生成新 Key"""
        self.revoke(old_key)
        # 从旧 Key 元数据中恢复 tenant_id 和 user_id
        meta = self._get_key_meta(old_key)
        return self.generate_key(meta["tenant_id"], meta["user_id"], meta["scopes"])
```

### 7.5 AI 安全防护 (LLM Firewall)

#### 7.5.1 双重护栏架构

```
用户输入
    │
    ▼
┌──────────────────────────────────────────────────┐
│ 输入护栏 (Input Guard)                             │
│                                                   │
│  ① Prompt Injection 检测                          │
│     模式匹配: "ignore previous instructions"      │
│     语义检测: LLM 判断输入是否试图越权             │
│     → 命中: 阻断请求 + 告警                       │
│                                                   │
│  ② Jailbreak 检测                                 │
│     对抗样本识别: DAN / 角色扮演 / 编码绕过        │
│     → 命中: 阻断请求 + 记录 attempt               │
│                                                   │
│  ③ PII 自动脱敏                                   │
│     身份证号 → 320***********1234                 │
│     手机号 → 138****5678                          │
│     银行卡 → 6222****1234                         │
│     → 脱敏后的内容传给 LLM                        │
│                                                   │
│  ④ 恶意意图识别                                   │
│     检测: 生成恶意代码 / 钓鱼邮件 / 虚假信息       │
│     → 命中: 阻断 + 安全告警                       │
└──────────────────────┬───────────────────────────┘
                       │ Pass
                       ▼
                  Agent 执行
                       │
                       ▼
┌──────────────────────────────────────────────────┐
│ 输出护栏 (Output Guard)                            │
│                                                   │
│  ① 有害内容过滤                                   │
│     政治敏感 / 暴力 / 色情 / 歧视                  │
│     → 命中: 替换为 "我无法回答这个问题"             │
│                                                   │
│  ② 幻觉检测                                       │
│     检查: 回答中的事实声称是否在引用来源中出现       │
│     未引用的声称 → 标记 confidence_downgrade       │
│     → 低置信度结果触发 HITL 审批                   │
│                                                   │
│  ③ 敏感信息防泄漏                                 │
│     检测: API Key / Token / 内部 IP / 数据库连接串  │
│     → 命中: 自动遮盖 + 安全告警                    │
│                                                   │
│  ④ 合规检查                                       │
│     行业监管关键词 (如金融行业: "保本""无风险")     │
│     → 命中: 阻断 + 合规告警                        │
└──────────────────────────────────────────────────┘
```

#### 7.5.2 Prompt Injection 检测实现

```python
class PromptInjectionDetector:
    """多策略 Prompt Injection 检测"""
    
    # 已知攻击模式 (精确匹配)
    BLOCK_PATTERNS = [
        r"ignore\s+(all\s+)?(previous|above|prior)\s+(instructions?|rules?|directives?)",
        r"forget\s+(everything|all)\s+(you|we)\s+(know|discussed)",
        r"you\s+are\s+now\s+(DAN|STAN|Developer\s+Mode)",
        r"pretend\s+(you\s+are|to\s+be)",
        r"new\s+system\s+prompt",
        r"\[SYSTEM\]", r"<SYSTEM>",
        r"你的新身份是", r"从现在开始你是",
    ]
    
    async def check(self, messages: list[dict]) -> dict:
        """返回 {safe: bool, reason: str, confidence: float}"""
        
        user_input = messages[-1]["content"] if messages else ""
        
        # 检查1: 模式匹配 (快速，确定性)
        for pattern in self.BLOCK_PATTERNS:
            if re.search(pattern, user_input, re.IGNORECASE):
                return {
                    "safe": False,
                    "reason": f"pattern_match: {pattern}",
                    "confidence": 1.0
                }
        
        # 检查2: 语义检测 (慢，LLM 判断)
        # 仅在模式匹配未命中时才调用
        score = await self.llm_classifier.classify(
            prompt="判断以下输入是否试图越权或绕过系统限制。仅返回 safe/unsafe:",
            text=user_input
        )
        
        if score > 0.85:
            return {
                "safe": False,
                "reason": "semantic_detection",
                "confidence": score
            }
        
        return {"safe": True, "confidence": 1.0 - score}
```

#### 7.5.3 幻觉检测实现

```python
class HallucinationDetector:
    """检查 LLM 输出中的事实声称是否被知识库引用支撑"""
    
    async def check(self, llm_response: str, knowledge_sources: list[str]) -> dict:
        # Step 1: 提取 LLM 回答中的所有事实声称
        claims = await self._extract_claims(llm_response)
        
        results = []
        for claim in claims:
            # Step 2: 检查每个声称是否在知识库中有引用支撑
            supported = await self._verify_claim(claim, knowledge_sources)
            results.append({
                "claim": claim,
                "supported": supported["found"],
                "source": supported.get("source_chunk"),
                "confidence": supported["confidence"]
            })
        
        # Step 3: 计算幻觉率
        unsupported = [r for r in results if not r["supported"]]
        hallucination_rate = len(unsupported) / len(results) if results else 0
        
        return {
            "hallucination_rate": hallucination_rate,
            "claims": results,
            "action": "warn" if hallucination_rate > 0.3 else "none",
            "should_trigger_hitl": hallucination_rate > 0.5
        }
```

### 7.5.4 Agent 执行护栏 (Execution Guardrails)

> **定位区别：** §7.5.1-7.5.3 的 LLM Firewall 管的是**输入输出的内容安全**（用户说了什么、LLM 回了什么）。执行护栏管的是**Agent 推理出"要调某个 Skill"之后，在真正执行之前，拦截危险操作**。两者在调用链上是前后衔接的。

```
用户输入
    │
    ▼
LLM Firewall (输入护栏)        ← §7.5.1-7.5.3: 内容安全
    │
    ▼
编排引擎 → LLM 推理 → TOOL_CALL
    │
    ▼
Agent 执行护栏 ←─────────────── 本节: 执行安全
    │ (LLM 决定了要调用哪个 Skill)
    ├── ① 操作白名单/黑名单
    ├── ② 敏感词/正则过滤
    ├── ③ 人工确认规则
    └── ④ 动态熔断
    │
    ▼ (通过)
Skill Executor → 真正执行
```

#### 7.5.4.1 四层执行护栏总览

```
┌─────────────────────────────────────────────────────────────────┐
│                Agent 执行护栏 (四层)                              │
│                                                                 │
│  编排引擎输出 TOOL_CALL 后，真正执行前:                            │
│                                                                 │
│  Layer 1: 操作白名单/黑名单                                       │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 声明式规则: 哪些 Skill/操作允许，哪些禁止                     │  │
│  │ 例: delete_order → blocked, claim_init → allowed_if(amount<1000)│
│  │ 命中 blacklist → 直接阻断，不进入后续护栏                     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                         │                                       │
│  Layer 2: 敏感词/正则过滤                                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 检查 Skill 参数中是否包含敏感内容                             │  │
│  │ 例: 参数包含 DROP TABLE / rm -rf / 内部域名 / 外部邮箱       │  │
│  │ 命中 → 阻断 + 告警                                          │  │
│  └───────────────────────────────────────────────────────────┘  │
│                         │                                       │
│  Layer 3: 人工确认规则 (HITL)                                    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 可配置哪些操作必须人工确认后才执行                             │  │
│  │ 例: amount>5000 / action=cancel_order / skill=delete_*     │  │
│  │ 命中 → 挂起等待人工审批                                     │  │
│  └───────────────────────────────────────────────────────────┘  │
│                         │                                       │
│  Layer 4: 动态熔断                                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ 实时监控异常模式: 短时间大量调用 / 异常参数组合               │  │
│  │ 触发 → 自动降级 (切换到 safe mode) 或暂停 Agent              │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

#### 7.5.4.2 操作白名单/黑名单

```yaml
# agent-guardrails.yaml — 每个 Agent 可独立配置
agent: logistics-exception-handler

execution_policy:
  # === 白名单模式: 仅允许列表中的操作 ===
  # 适用于安全敏感 Agent (如财务/合规)
  mode: blacklist   # whitelist | blacklist
  
  # === 黑名单: 禁止的操作 ===
  blacklist:
    - skill: delete_order       # 禁止删除订单
      reason: "订单删除不可逆, 需人工操作"
    
    - skill: modify_payment     # 禁止修改付款信息
      reason: "付款信息修改需财务审批"
    
    - skill: send_external_email
      params:
        recipient_domain_whitelist: ["@company.com"]  # 仅允许发送到公司域名
      reason: "禁止向外部邮箱发送邮件"
    
    - skill: claim_init         # 允许但有限制
      params:
        max_amount: 1000        # 理赔金额上限
      reason: "超过1000元的理赔需人工处理"
  
  # === 按行业叠加规则 ===
  industry_overrides:
    finance:                     # 金融行业额外规则
      blacklist:
        - skill: modify_credit_rating
        - skill: bypass_compliance_check
```

```python
class ExecutionPolicyEngine:
    """执行策略引擎 — 每次 TOOL_CALL 前调用"""
    
    async def check(self, skill_name: str, params: dict, 
                    agent_config: dict, context: dict) -> PolicyResult:
        
        policy = agent_config.get("execution_policy", {})
        mode = policy.get("mode", "blacklist")
        
        # === Layer 1: 白名单/黑名单检查 ===
        if mode == "whitelist":
            # 白名单模式: skill 必须在白名单中
            whitelist = [item["skill"] for item in policy.get("whitelist", [])]
            if skill_name not in whitelist:
                return PolicyResult(
                    allowed=False,
                    reason=f"Skill '{skill_name}' not in whitelist",
                    action="block"
                )
        
        # 黑名单检查
        for rule in policy.get("blacklist", []):
            if rule["skill"] == skill_name:
                # 检查参数限制
                if "params" in rule:
                    for param_name, constraint in rule["params"].items():
                        actual = params.get(param_name)
                        if isinstance(constraint, dict):
                            # max_amount 检查
                            if "max_amount" in constraint:
                                if actual and actual > constraint["max_amount"]:
                                    return PolicyResult(
                                        allowed=False,
                                        reason=f"{rule['reason']}: {param_name}={actual} > max={constraint['max_amount']}",
                                        action="require_approval",
                                        escalation_level="P2"
                                    )
                            # domain whitelist 检查
                            if "recipient_domain_whitelist" in constraint:
                                if actual and not any(actual.endswith(d) for d in constraint["recipient_domain_whitelist"]):
                                    return PolicyResult(
                                        allowed=False,
                                        reason=f"{rule['reason']}: domain not in whitelist",
                                        action="block"
                                    )
                        elif isinstance(constraint, list):
                            if actual not in constraint:
                                return PolicyResult(
                                    allowed=False,
                                    reason=f"{rule['reason']}: {param_name} not in allowed values",
                                    action="block"
                                )
                
                # 无条件禁止
                if "params" not in rule:
                    return PolicyResult(
                        allowed=False,
                        reason=rule["reason"],
                        action="block"
                    )
        
        return PolicyResult(allowed=True)
```

#### 7.5.4.3 敏感词/正则过滤

```python
class SensitiveContentFilter:
    """检查 Skill 调用参数中是否包含敏感内容"""
    
    # 高危模式——命中直接阻断
    CRITICAL_PATTERNS = [
        # SQL 注入
        (r"(?i)(DROP\s+TABLE|DELETE\s+FROM|TRUNCATE\s+TABLE|ALTER\s+TABLE)", 
         "疑似 SQL 注入"),
        # 命令注入
        (r"(?i)(rm\s+-rf|sudo\s+|curl\s+.*\|.*sh|wget\s+.*-O\s+/tmp)",
         "疑似命令注入"),
        # 路径遍历
        (r"(\.\.\/){2,}|(\.\.\\){2,}",
         "路径遍历攻击"),
        # 内部地址泄露
        (r"(10\.\d{1,3}|172\.(1[6-9]|2\d|3[01])|192\.168)\.\d{1,3}\.\d{1,3}",
         "内部 IP 地址"),
        # 数据库连接串
        (r"(?i)(jdbc:|mongodb://|redis://|postgresql://)",
         "数据库连接串泄露"),
    ]
    
    # 告警模式——不阻断但告警
    WARNING_PATTERNS = [
        # 外部邮箱
        (r"@(?!company\.com)[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
         "发送到外部邮箱"),
        # 大量金额
        (r"金额.*?(\d{5,})|amount.*?(\d{5,})",
         "涉及大额金额"),
        # 敏感文件路径
        (r"(?i)(/etc/passwd|/etc/shadow|~/.ssh|/root/)",
         "敏感文件路径"),
    ]
    
    def check(self, skill_name: str, params: dict) -> FilterResult:
        """检查 Skill 参数"""
        params_str = json.dumps(params, ensure_ascii=False)
        
        # 高危检查
        for pattern, reason in self.CRITICAL_PATTERNS:
            match = re.search(pattern, params_str)
            if match:
                return FilterResult(
                    passed=False,
                    action="block",
                    reason=f"{reason}: 匹配 '{match.group()}'"
                )
        
        # 告警检查
        warnings = []
        for pattern, reason in self.WARNING_PATTERNS:
            match = re.search(pattern, params_str)
            if match:
                warnings.append({
                    "pattern": reason,
                    "matched": match.group()
                })
        
        return FilterResult(
            passed=True,
            warnings=warnings,
            action="warn" if warnings else "pass"
        )
```

#### 7.5.4.4 人工确认规则 (HITL)

```yaml
# hitl-rules.yaml — 可配置的人工确认规则
agent: logistics-exception-handler

hitl_rules:
  # === 按操作类型 ===
  by_action:
    - action: cancel_order
      always_require_approval: true
      approval_message: "Agent 请求取消订单 {{order_id}}，请确认"
    
    - action: initiate_claim
      condition: "amount > 1000"
      approval_message: "Agent 请求发起理赔 {{amount}} 元，请确认"
    
    - action: modify_delivery_address
      always_require_approval: true
  
  # === 按金额阈值 ===
  by_amount:
    - threshold: 5000
      currency: CNY
      scope: any_action           # 任何涉及此金额的操作
  
  # === 按置信度 ===
  by_confidence:
    - threshold: 0.75             # Agent 自信度 < 0.75 → 审批
    - threshold: 0.85
      condition: "involves_compensation"  # 涉及赔偿时阈值提高
  
  # === 按异常等级 ===
  by_severity:
    - level: P1                   # P1 严重异常 → 始终审批
    - level: P2
      condition: "involves_compensation"
  
  # === 按客户等级 ===
  by_customer_tier:
    - tier: VIP                   # VIP 客户 → 所有操作审批
    - tier: KEY_ACCOUNT
      condition: "amount > 1000"
  
  # === 审批超时策略 ===
  approval_timeout:
    default: 3600                  # 默认 1 小时
    by_severity:
      P1: 1800                     # P1 严重异常: 30 分钟
      P2: 3600
      P3: 7200                     # P3 轻微: 2 小时
    on_timeout: auto_reject        # auto_reject | auto_approve | escalate
```

```python
class HITLEngine:
    """人工确认引擎"""
    
    async def check(self, skill_name: str, params: dict, 
                    context: dict) -> HITLDecision:
        
        rules = await self.db.get_hitl_rules(context["agent_name"])
        
        checks = []
        
        # 按操作类型
        for rule in rules.get("by_action", []):
            if rule["action"] == skill_name:
                if rule.get("always_require_approval"):
                    checks.append(HITLCheck(
                        trigger="by_action",
                        reason=f"{skill_name} 必须人工审批",
                        message=rule.get("approval_message", "").format(**params)
                    ))
                elif rule.get("condition"):
                    if self._eval_condition(rule["condition"], params, context):
                        checks.append(HITLCheck(
                            trigger="by_action",
                            reason=f"{skill_name} 满足条件: {rule['condition']}"
                        ))
        
        # 按金额
        for rule in rules.get("by_amount", []):
            amount = self._extract_amount(params)
            if amount and amount > rule["threshold"]:
                checks.append(HITLCheck(
                    trigger="by_amount",
                    reason=f"金额 {amount} > {rule['threshold']}"
                ))
        
        # 按置信度
        for rule in rules.get("by_confidence", []):
            agent_confidence = context.get("confidence", 1.0)
            if agent_confidence < rule["threshold"]:
                checks.append(HITLCheck(
                    trigger="by_confidence",
                    reason=f"置信度 {agent_confidence} < {rule['threshold']}"
                ))
        
        # 按客户等级
        customer_tier = context.get("user_tier", "NORMAL")
        for rule in rules.get("by_customer_tier", []):
            if customer_tier == rule["tier"]:
                checks.append(HITLCheck(
                    trigger="by_customer_tier",
                    reason=f"客户等级 {customer_tier}"
                ))
        
        if checks:
            return HITLDecision(
                requires_approval=True,
                checks=checks,
                timeout=self._get_timeout(rules, context)
            )
        
        return HITLDecision(requires_approval=False)
```

#### 7.5.4.5 动态熔断

```python
class CircuitBreaker:
    """异常模式检测 + 自动熔断"""
    
    def __init__(self):
        self.redis = RedisClient()
        self.window = 300  # 5 分钟窗口
    
    async def check(self, agent_name: str, skill_name: str, 
                    tenant_id: str) -> BreakerResult:
        
        # 指标1: 同 Agent 同 Skill 调用频率
        key = f"cb:{tenant_id}:{agent_name}:{skill_name}:count"
        count = await self.redis.incr(key)
        await self.redis.expire(key, self.window)
        
        if count > 50:  # 5 分钟内同一 Skill 调用超 50 次
            return BreakerResult(
                action="throttle",
                reason=f"Skill '{skill_name}' 调用频率异常: {count}次/{self.window}s"
            )
        
        # 指标2: 连续被护栏拒绝
        block_key = f"cb:{tenant_id}:{agent_name}:blocked"
        blocked_count = await self.redis.get(block_key) or 0
        
        if int(blocked_count) > 10:  # 连续 10 次被拒绝
            return BreakerResult(
                action="suspend_agent",
                reason=f"Agent '{agent_name}' 连续 {blocked_count} 次操作被护栏拦截, 自动暂停"
            )
        
        # 指标3: 异常参数模式 (如短时间内发送到不同外部邮箱)
        # 指标4: Token 消耗异常飙升
        
        return BreakerResult(action="pass")
    
    async def record_block(self, agent_name: str, tenant_id: str):
        """记录一次拦截"""
        key = f"cb:{tenant_id}:{agent_name}:blocked"
        await self.redis.incr(key)
        await self.redis.expire(key, self.window)
```

#### 7.5.4.6 四层护栏执行流程

```python
# orchestrator.py — execute_skill 节点中的护栏调用
async def execute_skill_with_guardrails(self, state: AgentState) -> AgentState:
    skill_name = state["pending_skill"]
    skill_params = state["pending_skill_params"]
    agent_config = state["agent_config"]
    
    # === Layer 1: 操作白名单/黑名单 ===
    policy_result = await self.execution_policy.check(
        skill_name, skill_params, agent_config, state
    )
    if not policy_result.allowed:
        if policy_result.action == "block":
            await self.circuit_breaker.record_block(state["agent_name"], state["tenant_id"])
            return self._respond_blocked(state, policy_result.reason)
        if policy_result.action == "require_approval":
            state["pending_approval"] = policy_result
            return await self.human_approval(state)
    
    # === Layer 2: 敏感词/正则过滤 ===
    filter_result = self.sensitive_filter.check(skill_name, skill_params)
    if not filter_result.passed:
        await self.circuit_breaker.record_block(state["agent_name"], state["tenant_id"])
        return self._respond_blocked(state, filter_result.reason)
    
    # === Layer 3: 人工确认规则 ===
    hitl_decision = await self.hitl_engine.check(skill_name, skill_params, state)
    if hitl_decision.requires_approval:
        state["pending_approval"] = hitl_decision
        return await self.human_approval(state)
    
    # === Layer 4: 动态熔断 ===
    breaker_result = await self.circuit_breaker.check(
        state["agent_name"], skill_name, state["tenant_id"]
    )
    if breaker_result.action == "throttle":
        return self._respond_throttled(state, breaker_result.reason)
    if breaker_result.action == "suspend_agent":
        await self._suspend_agent(state["agent_name"], breaker_result.reason)
        return self._respond_suspended(state, breaker_result.reason)
    
    # === 全部通过 → 真正执行 ===
    result = await self.skill_registry.invoke(skill_name, skill_params)
    return result
```

### 7.6 数据安全

#### 7.6.1 数据分类与保护策略

| 数据分类 | 示例 | 传输 | 存储 | 访问控制 | 保留期 |
|---------|------|:---:|:---:|------|------|
| **公开** | Agent 市场信息、技能描述 | TLS | — | 无需认证 | 永久 |
| **内部** | Agent 定义、Prompt 模板、评估结果 | TLS 1.3 | AES-256 | RBAC 鉴权 | 按需 |
| **敏感** | 对话记录、用户查询、Skill 调用日志 | TLS 1.3 | AES-256 + 字段级加密 | RBAC + ABAC | 365 天 |
| **机密** | PII (手机号/身份证)、API Key、Token | TLS 1.3 + mTLS | AES-256 + 应用层加密 | RBAC + ABAC + 审批 | 合规要求 |
| **监管** | 审计日志、金融合规记录 | TLS 1.3 | AES-256 + 写入后不可修改 | 仅 auditor 角色 | 7 年 (合规) |

#### 7.6.2 PII 脱敏策略

```python
class PIIDesensitizer:
    """自动识别并脱敏个人身份信息"""
    
    PATTERNS = {
        "id_card": (r"\d{6}(19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\d{3}[\dXx]", 
                    lambda m: m[:6] + "********" + m[-4:]),
        "phone": (r"1[3-9]\d{9}", 
                  lambda m: m[:3] + "****" + m[-4:]),
        "bank_card": (r"\d{16,19}", 
                      lambda m: m[:4] + "****" + m[-4:]),
        "email": (r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}",
                  lambda m: m[0] + "***@" + m.split("@")[1]),
    }
    
    def desensitize(self, text: str) -> tuple[str, list]:
        """脱敏处理, 返回 (脱敏后文本, 脱敏记录)"""
        result = text
        records = []
        
        for pii_type, (pattern, replacer) in self.PATTERNS.items():
            matches = re.finditer(pattern, result)
            for match in matches:
                original = match.group()
                masked = replacer(original)
                result = result.replace(original, masked)
                records.append({
                    "type": pii_type,
                    "original_hash": hashlib.sha256(original.encode()).hexdigest(),
                    "position": match.start()
                })
        
        return result, records
```

#### 7.6.3 数据出境管控

```yaml
# 数据驻留策略
data_residency:
  rules:
    - tenant_region: cn
      data_must_reside_in: cn
      models_allowed: [deepseek-v3, qwen-max]   # 仅国产模型
      cross_border_transfer: false
    
    - tenant_region: eu
      data_must_reside_in: eu
      models_allowed: [claude-sonnet-4-6]        # 仅 EU 托管模型
      cross_border_transfer: false
    
    - tenant_region: global
      data_must_reside_in: any
      models_allowed: [*]
      cross_border_transfer: true
```

### 7.7 审计追溯

#### 7.7.1 审计日志模型

```sql
-- 审计日志表 (不可篡改设计)
CREATE TABLE audit_log (
    id              BIGSERIAL PRIMARY KEY,
    event_id        UUID NOT NULL UNIQUE,        -- 幂等 ID
    tenant_id       TEXT NOT NULL,
    user_id         TEXT,
    event_type      TEXT NOT NULL,               -- agent.run | skill.call | prompt.edit | auth.login
    resource_type   TEXT NOT NULL,               -- agent | skill | prompt | session
    resource_id     TEXT NOT NULL,
    action          TEXT NOT NULL,               -- create | read | update | delete | execute
    request_detail  JSONB,                       -- 请求摘要 (已脱敏)
    response_status TEXT,                        -- success | failure | blocked
    source_ip       INET,
    user_agent      TEXT,
    trace_id        TEXT,                        -- 关联 OpenTelemetry Trace
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    
    -- 防篡改: 每条记录包含上一条的哈希
    prev_hash       TEXT,
    current_hash    TEXT GENERATED ALWAYS AS (
        encode(digest(
            event_id::text || tenant_id || event_type || resource_type || 
            resource_id || action || created_at::text || COALESCE(prev_hash, ''),
            'sha256'
        ), 'hex')
    ) STORED
);

-- 索引
CREATE INDEX idx_audit_tenant_time ON audit_log(tenant_id, created_at DESC);
CREATE INDEX idx_audit_event_type ON audit_log(event_type);
CREATE INDEX idx_audit_trace ON audit_log(trace_id);
```

#### 7.7.2 审计事件分类

| 事件类型 | 记录内容 | 保留期 |
|---------|---------|:---:|
| `agent.run` | 谁在何时运行了哪个 Agent，Query 摘要 (脱敏)，Skill 调用链路，耗时 | 365 天 |
| `agent.create/edit/delete` | Agent 定义变更前后 diff | 永久 |
| `skill.call` | 技能名称、输入参数摘要、返回状态 | 365 天 |
| `prompt.edit` | Prompt 变更前后 diff、变更人 | 永久 |
| `auth.login` | 登录时间、IP、User-Agent、成功/失败 | 90 天 |
| `auth.api_key` | API Key 创建/吊销 | 永久 |
| `model.call` | 模型名称、Token 用量、延迟、是否命中缓存 | 90 天 |
| `hitl.approve/reject` | 审批人、审批内容摘要、决策 | 365 天 |
| `data.export` | 导出内容范围、导出人、导出时间 | 永久 |

#### 7.7.3 审计日志写入

```python
class AuditLogger:
    """全链路审计日志"""
    
    async def log(self, event: AuditEvent):
        # ① 写入 PG (主存储)
        await self.db.execute("""
            INSERT INTO audit_log (event_id, tenant_id, user_id, event_type,
                resource_type, resource_id, action, request_detail, 
                response_status, source_ip, user_agent, trace_id, prev_hash)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
                (SELECT current_hash FROM audit_log 
                 WHERE tenant_id = $2 
                 ORDER BY created_at DESC LIMIT 1))
        """, event.event_id, event.tenant_id, event.user_id, ...)
        
        # ② 发送到 Kafka (异步消费 → 归档到 MinIO)
        await self.kafka.send("audit-events", event.to_json())
    
    async def verify_integrity(self, tenant_id: str) -> dict:
        """验证审计链完整性——检测是否被篡改"""
        rows = await self.db.fetch("""
            SELECT event_id, current_hash, prev_hash 
            FROM audit_log 
            WHERE tenant_id = $1 
            ORDER BY created_at
        """, tenant_id)
        
        broken_links = []
        for i in range(1, len(rows)):
            if rows[i]["prev_hash"] != rows[i-1]["current_hash"]:
                broken_links.append({
                    "event_id": rows[i]["event_id"],
                    "expected": rows[i-1]["current_hash"],
                    "actual": rows[i]["prev_hash"]
                })
        
        return {
            "total_events": len(rows),
            "broken_links": len(broken_links),
            "integrity": "intact" if len(broken_links) == 0 else "compromised"
        }
```

### 7.8 安全运营

#### 7.8.1 安全告警规则

```yaml
# Prometheus AlertManager 规则
groups:
  - name: security_alerts
    rules:
      - alert: PromptInjectionAttempt
        expr: rate(llm_firewall_blocked_total{reason="prompt_injection"}[5m]) > 5
        severity: warning
        annotations:
          summary: "Prompt Injection 尝试频率异常"
      
      - alert: JailbreakAttempt
        expr: rate(llm_firewall_blocked_total{reason="jailbreak"}[5m]) > 1
        severity: critical
        annotations:
          summary: "检测到 Jailbreak 攻击尝试"
      
      - alert: HighHallucinationRate
        expr: agent_hallucination_rate > 0.3
        for: 10m
        severity: warning
        annotations:
          summary: "Agent 幻觉率超过 30%"
      
      - alert: UnauthorizedAccess
        expr: rate(auth_failed_total[5m]) > 20
        severity: critical
        annotations:
          summary: "认证失败频率异常，可能存在暴力破解"
      
      - alert: ApiKeyLeaked
        expr: api_key_used_from_new_ip == 1
        severity: critical
        annotations:
          summary: "API Key 从新 IP 首次使用，可能存在泄露"
      
      - alert: AuditChainBroken
        expr: audit_integrity_check_failed == 1
        severity: critical
        annotations:
          summary: "审计链完整性校验失败，可能存在篡改"
```

#### 7.8.2 安全响应矩阵

| 事件 | 自动响应 | 人工响应 |
|------|---------|---------|
| Prompt Injection 检测命中 | 阻断请求 + 记录 attempt | 每日 review attempt 日志 |
| 同一 IP 5 分钟内 5+ 次 Injection | IP 临时封禁 30min | 安全工程师确认 |
| Jailbreak 检测命中 | 阻断 + 封禁 IP 1h | 立即通知安全团队 |
| 幻觉率 > 30% 持续 10min | Agent 自动降级 (切换到备选 Prompt) | 开发者排查知识库 |
| 认证失败 20+ 次/5min | IP 临时封禁 15min | 通知用户 |
| API Key 从新 IP 使用 | 发送验证邮件给 Key 所有者 | Key 所有者确认后放行 |
| 审计链完整性校验失败 | 立即告警 | 安全团队紧急排查 |

### 7.9 计费模型

**基础平台费 (订阅制):** Free → Pro → Business → Enterprise

**用量计费 (Pay-as-you-go):**
- Token 消耗 (按模型差异化定价)
- 知识库存储 (GB/月)
- Agent 调用次数
- 技能市场消费

**增值服务:**
- 行业包订阅
- 专属 GPU 实例
- 私有化部署 license
- SLA 升级

### 7.10 开发者体验

| 工具 | 说明 |
|------|------|
| **SDK** | Python / JS/TS / Java |
| **CLI** | `$ ai agent deploy`、`$ ai skill create` |
| **VS Code 插件** | 一键创建、本地调试 |
| **Agent Playground** | 在线调试沙箱：对话面板 + 调试面板 (Trace/步骤状态/耗时) + 配置面板 + 评估面板 |
| **API Docs** | OpenAPI 规范 + 交互式文档 |

---

## 8. 技术选型矩阵

### 8.1 核心技术栈

| 层级 | 组件 | 选型 | 选型理由 |
|------|------|------|---------|
| **容器编排** | K8s | K8s | 行业标准，混合部署必备 |
| **GPU 推理** | 推理引擎 | vLLM + TGI | vLLM 吞吐最高，TGI 生态兼容好 |
| **向量数据库** | 主存储 | Milvus | 分布式能力强，十亿级规模验证 |
| | 热缓存 | Qdrant | 内存映射，P99 < 5ms |
| **图数据库** | 知识图谱 | Neo4j | 生态最成熟，Cypher 查询最普及 |
| **消息队列** | 事件总线 | Kafka | 生态最广 |
| **缓存** | 分布式 | Redis Cluster | 生态+性能+持久化 |
| **关系数据库** | 业务数据 | PostgreSQL | JSON 支持好，PGVector 复用 |
| **对象存储** | 文件/日志 | MinIO | S3 兼容，私有化部署友好 |
| **模型网关** | LLM 接入 | **LiteLLM Proxy 内核 + 自研策略层** | LiteLLM 提供 100+ 模型统一接入、OpenAI API 兼容、内置 Router/Retry/Fallback/Load Balance；自研策略层注入业务路由(速度/质量/成本/合规)、语义缓存、安全检测、多租户限流 |
| **Agent 框架** | 编排引擎 | LangGraph + 自研 | 社区活跃，图编排成熟 |
| **RAG 引擎** | 检索增强 | LlamaIndex + 自研 | 检索管道灵活，可定制性强 |
| **可观测性** | Metrics | Prometheus + Grafana | 标准选型 |
| | Tracing | OpenTelemetry + Jaeger | CNCF 标准 |
| | Logging | Loki + Promtail | 与 Prometheus 统一栈 |
| **安全** | 身份认证 | Keycloak | 开源，支持私有化部署 |
| | 权限 | OpenFGA | ReBAC 支持好，适合 Agent 权限场景 |
| **API 网关** | 流量入口 | APISIX | 性能好，插件丰富 |
| **CI/CD** | 持续交付 | ArgoCD + GitHub Actions | GitOps 模式 |

### 8.2 关键决策

**D1: Agent 编排 — LangGraph + 自研策略层**：LangGraph 提供图编排+Checkpoint 内核能力，在此基础上自研 Simple/Chain/Router/Graph/Debate 策略层。

**D2: 不选 Dify/Coze 作为底座**：行业深度不够、企业级能力欠缺、定制能力有限、生态锁定、商业风险。

**D3: 模型网关选型 — LiteLLM Proxy 内核 + 自研策略层**：LiteLLM 提供 100+ 模型统一接入、OpenAI API 兼容、内置 Router/Retry/Fallback/Load Balance/Callback Hook，省掉 60% 基础代码。自研策略层通过 Callback Hook 注入：业务路由(速度/质量/成本/合规四维度)、语义缓存(非精确匹配，命中率 20-35%)、Prompt Injection 安全检测、多租户限流。所有外部依赖通过 LiteLLM Callback Hook 注入，不 fork 源码。

**D4: 国产化适配策略**：所有外部依赖通过 Adapter 模式接入，国产替代 = 实现新 Adapter，不改核心逻辑。三级适配：基础设施(国产 GPU/OS/芯片) → 中间件(达梦/OceanBase/RocketMQ) → 模型(通义/文心/智谱/DeepSeek)。

---

## 9. 部署架构与演进路线

### 9.1 SaaS 部署拓扑

![SaaS 部署拓扑](images/fw-arch-14-deployment.png)

**私有化部署最小拓扑**：K8s 3-Node Cluster，最低 64 vCPU + 256GB RAM + 1×A100 GPU (或 2×T4)。

### 9.2 分期路线图

```
Phase 1: MVP (0-6月)
  目标: 1 个行业跑通 3 个 Agent 场景
  交付: 模型网关 + 基础RAG + Agent运行时(Simple/Chain) + Prompt管理 + 物流行业3Agent模板
  团队: 后端4 + AI3 + 前端2 + DevOps1

Phase 2: 平台化 (6-12月)
  目标: Agent 平台完备，3 个行业可用
  交付: 全生命周期 + Router/Graph编排 + 技能市场 + 分层记忆 + 评估体系 + 多租户计费 + 私有化
  团队: 后端8 + AI6 + 前端4 + DevOps2

Phase 3: 生态化 (12-24月)
  目标: 平台生态成形，伙伴可自建行业方案
  交付: 多Agent协作(Hierarchical/Debate) + 知识图谱 + ISV伙伴平台 + 6+行业方案 + 信创适配 + 多活
  团队: 后端12 + AI10 + 前端6 + DevOps3

Phase 4: 智能化 (24-36月)
  目标: AI 自主驱动平台运营，Agent 自我进化
  交付: Agent自动优化 + 跨Agent学习 + 行业知识自动发现 + Agent间市场 + 全球化部署
```

### 9.3 组织架构

**组织架构：**
- **AI 平台负责人**
  - **平台工程组**: 基础设施/网关/安全/多租户/开发者工具
  - **AI 算法组**: Agent 引擎/模型网关/RAG/知识图谱/评估
  - **行业方案组**: 物流/金融/制造/伙伴赋能/解决方案架构
  - **产品 & 设计**: PM×2 + UX×2 + Tech Writer×1

### 9.4 关键风险与缓解

| 风险 | 影响 | 概率 | 缓解措施 |
|------|------|------|---------|
| **模型能力瓶颈** | 高 | 中 | 多模型网关+Falback，不绑定单一供应商 |
| **客户 AI 认知不足** | 高 | 高 | Phase 1 聚焦灯塔客户，联合打磨标杆案例 |
| **数据安全合规** | 高 | 中 | 安全体系 Day 1 构建；私有化 Phase 2 上线 |
| **竞品快速跟进** | 中 | 高 | 行业 know-how 壁垒（连接器+知识库+本体）+ ISV 生态绑定 |
| **GPU 供应链风险** | 中 | 低 | 国产芯片支持；多云混合调度 |
| **Agent 不可控行为** | 高 | 中 | 多级安全护栏；Human-in-the-loop；灰度发布 |

---

## 10. 从零搭建路线图

### 10.1 搭建总览

```
![从零搭建五阶段路线图](images/fw-arch-19-build-roadmap.png)
```

### 10.2 Phase 1：基础设施层搭建（Week 1-2）

#### 10.2.1 K8s 集群准备

```bash
# 方案 A: 自建 K8s (推荐生产环境)
# 3 Master + 5 Worker, Calico CNI, MetalLB

# 方案 B: 开发/测试环境快速搭建
kind create cluster --name ai-platform --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
- role: worker
- role: worker
- role: worker
EOF

# 验证集群就绪
kubectl get nodes
kubectl create namespace ai-platform
```

#### 10.2.2 GPU Operator 部署

```bash
# NVIDIA GPU Operator
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm install gpu-operator nvidia/gpu-operator \
  --namespace gpu-operator --create-namespace \
  --set driver.enabled=true \
  --set toolkit.enabled=true

# 验证 GPU 可用
kubectl describe nodes | grep nvidia.com/gpu

# 创建 GPU 节点池标签
kubectl label node gpu-node-1 accelerator=nvidia-a100
kubectl label node gpu-node-2 accelerator=nvidia-h100
```

#### 10.2.3 基础设施组件部署

```bash
# 1. PostgreSQL (业务数据)
helm install postgresql bitnami/postgresql \
  --namespace ai-platform \
  --set auth.database=ai_platform \
  --set primary.persistence.size=200Gi

# 2. Redis Cluster (缓存/会话/限流)
helm install redis bitnami/redis-cluster \
  --namespace ai-platform \
  --set replicaCount=3

# 3. Milvus (向量数据库)
helm install milvus milvus/milvus \
  --namespace ai-platform \
  --set standalone.resources.limits.memory=32Gi

# 4. Neo4j (图数据库)
helm install neo4j neo4j/neo4j \
  --namespace ai-platform

# 5. Kafka (消息队列)
helm install kafka bitnami/kafka \
  --namespace ai-platform \
  --set replicaCount=3

# 6. MinIO (对象存储)
helm install minio bitnami/minio \
  --namespace ai-platform \
  --set mode=distributed \
  --set persistence.size=500Gi

# 7. Prometheus + Grafana (可观测性)
helm install kube-prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

#### 10.2.4 基础设施验证检查清单

| # | 检查项 | 验证命令 | 预期结果 |
|---|--------|---------|---------|
| 1 | K8s 集群节点就绪 | `kubectl get nodes` | 全部 Ready |
| 2 | GPU 可调度 | `kubectl describe nodes \| grep nvidia.com/gpu` | >=1 GPU |
| 3 | PostgreSQL 连接 | `kubectl exec -it deploy/postgresql -- psql -U postgres` | 进入 psql |
| 4 | Redis 读写 | `kubectl exec -it deploy/redis -- redis-cli PING` | PONG |
| 5 | Milvus 健康 | `curl http://milvus:9091/healthz` | 200 OK |
| 6 | Neo4j 可访问 | `curl http://neo4j:7474` | 200 OK |
| 7 | Kafka Topic 创建 | `kafka-topics.sh --create --topic test` | Created |
| 8 | MinIO Bucket | `mc mb ai-platform/test` | Bucket created |
| 9 | Prometheus Target | 访问 Grafana → Targets | All UP |
| 10 | 日志采集 | 查询 Loki | 有日志流入 |

### 10.3 Phase 2：AI 能力层部署（Week 3-4）

#### 10.3.1 模型推理引擎部署

```bash
# vLLM 部署 (高吞吐推理)
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm-server
  namespace: ai-platform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vllm-server
  template:
    metadata:
      labels:
        app: vllm-server
    spec:
      nodeSelector:
        accelerator: nvidia-a100
      containers:
      - name: vllm
        image: vllm/vllm-openai:latest
        args:
        - --model
        - deepseek-ai/DeepSeek-V3
        - --gpu-memory-utilization
        - "0.9"
        - --max-model-len
        - "32768"
        ports:
        - containerPort: 8000
        resources:
          limits:
            nvidia.com/gpu: 4
EOF
```

#### 10.3.2 模型网关部署

```yaml
# model-gateway-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: model-gateway-config
  namespace: ai-platform
data:
  models.yaml: |
    providers:
      - name: openai
        models: [gpt-4o, gpt-4o-mini]
        endpoint: https://api.openai.com/v1
        api_key_env: OPENAI_API_KEY
      
      - name: anthropic
        models: [claude-opus-4-7, claude-sonnet-4-6]
        endpoint: https://api.anthropic.com/v1
        api_key_env: ANTHROPIC_API_KEY
      
      - name: vllm-self-hosted
        models: [deepseek-v3]
        endpoint: http://vllm-server.ai-platform:8000/v1
      
      - name: tongyi
        models: [qwen-max, qwen-plus]
        endpoint: https://dashscope.aliyuncs.com/compatible-mode/v1
        api_key_env: DASHSCOPE_API_KEY
    
    routing:
      default: anthropic/claude-sonnet-4-6
      rules:
        - pattern: "简单对话|FAQ|基础查询"
          target: vllm-self-hosted/deepseek-v3
        - pattern: "复杂推理|代码生成|合规审查"
          target: anthropic/claude-opus-4-7
        - pattern: "合规|数据敏感|私有数据"
          target: vllm-self-hosted/deepseek-v3
        - pattern: "嵌入|embedding"
          target: vllm-self-hosted/deepseek-v3
    
    fallback:
      anthropic/claude-opus-4-7:
        - anthropic/claude-sonnet-4-6
        - openai/gpt-4o
        - vllm-self-hosted/deepseek-v3
      vllm-self-hosted/deepseek-v3:
        - tongyi/qwen-plus
        - openai/gpt-4o-mini
```

#### 10.3.3 RAG 引擎部署

```bash
# 1. Embedding Service
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: embedding-service
  namespace: ai-platform
spec:
  replicas: 3
  selector:
    matchLabels:
      app: embedding-service
  template:
    metadata:
      labels:
        app: embedding-service
    spec:
      containers:
      - name: embedding
        image: ai-platform/embedding-service:latest
        ports:
        - containerPort: 8080
        env:
        - name: MODEL_NAME
          value: BAAI/bge-large-zh-v1.5
        - name: MILVUS_HOST
          value: milvus.ai-platform
        resources:
          limits:
            nvidia.com/gpu: 1
EOF

# 2. 文档处理管道
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: doc-processor
  namespace: ai-platform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: doc-processor
  template:
    metadata:
      labels:
        app: doc-processor
    spec:
      containers:
      - name: doc-processor
        image: ai-platform/doc-processor:latest
        ports:
        - containerPort: 8081
        env:
        - name: EMBEDDING_SERVICE
          value: http://embedding-service.ai-platform:8080
        - name: CHUNK_SIZE
          value: "512"
        - name: CHUNK_OVERLAP
          value: "50"
EOF

# 3. 检索服务
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: retriever-service
  namespace: ai-platform
spec:
  replicas: 3
  selector:
    matchLabels:
      app: retriever-service
  template:
    metadata:
      labels:
        app: retriever-service
    spec:
      containers:
      - name: retriever
        image: ai-platform/retriever:latest
        ports:
        - containerPort: 8082
        env:
        - name: MILVUS_HOST
          value: milvus.ai-platform
        - name: ES_HOST
          value: http://elasticsearch.ai-platform:9200
        - name: NEO4J_URI
          value: bolt://neo4j.ai-platform:7687
        - name: EMBEDDING_SERVICE
          value: http://embedding-service.ai-platform:8080
EOF
```

#### 10.3.4 Prompt Hub 部署

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: prompt-hub
  namespace: ai-platform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: prompt-hub
  template:
    metadata:
      labels:
        app: prompt-hub
    spec:
      containers:
      - name: prompt-hub
        image: ai-platform/prompt-hub:latest
        ports:
        - containerPort: 8083
        env:
        - name: DB_HOST
          value: postgresql.ai-platform
        - name: DB_NAME
          value: ai_platform
EOF
```

#### 10.3.5 AI 能力层验证检查清单

| # | 检查项 | 验证方法 | 预期 |
|---|--------|---------|------|
| 1 | vLLM 推理可用 | `curl http://vllm-server:8000/v1/models` | 返回模型列表 |
| 2 | 模型网关路由 | 发送不同意图请求 | 路由到不同模型 |
| 3 | 模型网关 Fallback | 模拟主模型超时 | 自动切换到备选 |
| 4 | Embedding 服务 | `curl -X POST /embed -d '{"text":"测试"}'` | 返回 1024 维向量 |
| 5 | 文档处理管道 | 上传测试 PDF | 成功分块+入库 |
| 6 | 检索召回 | 发送 Query | 返回 Top-K 结果 |
| 7 | Prompt Hub | 创建/发布/回滚 Prompt | 版本正常切换 |

### 10.4 Phase 3：Agent 平台层部署（Week 5-8）

#### 10.4.1 Agent 运行时部署

```yaml
# agent-runtime-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: agent-runtime
  namespace: ai-platform
spec:
  replicas: 3
  selector:
    matchLabels:
      app: agent-runtime
  template:
    spec:
      containers:
      - name: agent-runtime
        image: ai-platform/agent-runtime:v1.0
        ports:
        - containerPort: 8080
        env:
        - name: MODEL_GATEWAY_URL
          value: http://model-gateway.ai-platform/v1
        - name: RETRIEVER_URL
          value: http://retriever-service.ai-platform:8082
        - name: PROMPT_HUB_URL
          value: http://prompt-hub.ai-platform:8083
        - name: MEMORY_REDIS_URL
          value: redis://redis.ai-platform:6379
        - name: MEMORY_MILVUS_HOST
          value: milvus.ai-platform
        - name: SKILL_REGISTRY_URL
          value: http://skill-registry.ai-platform:8084
        - name: EVENTS_KAFKA_BROKERS
          value: kafka.ai-platform:9092
```

#### 10.4.2 Agent 编排引擎核心代码骨架

```python
# agent-runtime/orchestrator.py
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.sqlite import SqliteSaver
from typing import TypedDict, List, Annotated
import operator

class AgentState(TypedDict):
    messages: Annotated[List[str], operator.add]
    current_step: int
    max_steps: int
    skill_calls: List[dict]
    memory_context: str
    knowledge_context: str
    human_approval_required: bool

class Orchestrator:
    """Agent 编排引擎 — 在 LangGraph 之上自研策略层"""
    
    def __init__(self, agent_config: dict):
        self.config = agent_config
        self.max_steps = agent_config.get("max_steps", 15)
        self.checkpointer = SqliteSaver.from_conn_string("checkpoints.db")
        
    def build_graph(self) -> StateGraph:
        workflow = StateGraph(AgentState)
        
        # 节点
        workflow.add_node("understand", self.understand_intent)
        workflow.add_node("retrieve", self.retrieve_knowledge)
        workflow.add_node("recall", self.recall_memory)
        workflow.add_node("reason", self.llm_reason)
        workflow.add_node("execute_skill", self.execute_skill)
        workflow.add_node("human_approval", self.human_approval)
        workflow.add_node("respond", self.generate_response)
        
        # 边 (编排策略)
        workflow.set_entry_point("understand")
        workflow.add_edge("understand", "retrieve")
        workflow.add_edge("retrieve", "recall")
        workflow.add_edge("recall", "reason")
        
        # 条件边 — Router 策略
        workflow.add_conditional_edges(
            "reason",
            self.decide_next_action,
            {
                "call_skill": "execute_skill",
                "need_approval": "human_approval",
                "respond": "respond",
                "max_steps": END
            }
        )
        workflow.add_edge("execute_skill", "reason")  # 循环回 reason
        workflow.add_edge("human_approval", "respond")
        workflow.add_edge("respond", END)
        
        return workflow.compile(checkpointer=self.checkpointer)
    
    def decide_next_action(self, state: AgentState) -> str:
        if state["current_step"] >= self.max_steps:
            return "max_steps"
        last_message = state["messages"][-1] if state["messages"] else ""
        if "TOOL_CALL:" in last_message:
            return "call_skill"
        if state.get("human_approval_required"):
            return "need_approval"
        return "respond"
    
    async def understand_intent(self, state: AgentState) -> AgentState:
        """Step 1: 意图理解 — 分类 + 提取槽位"""
        ...
    
    async def retrieve_knowledge(self, state: AgentState) -> AgentState:
        """Step 2: 知识检索 — 多路召回 + 融合排序"""
        ...
    
    async def recall_memory(self, state: AgentState) -> AgentState:
        """Step 3: 记忆回忆 — 短期+长期记忆"""
        ...
    
    async def llm_reason(self, state: AgentState) -> AgentState:
        """Step 4: LLM 推理 — 组装 Context → 调用模型网关 → 解析输出"""
        ...
    
    async def execute_skill(self, state: AgentState) -> AgentState:
        """Step 5: 技能执行 — 从 Skill Registry 获取技能并调用"""
        ...
    
    async def human_approval(self, state: AgentState) -> AgentState:
        """Step 6: 人工审批 — 高风险操作触发"""
        ...
    
    async def generate_response(self, state: AgentState) -> AgentState:
        """Step 7: 生成最终回复"""
        ...
```

#### 10.4.3 技能注册中心

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: skill-registry
  namespace: ai-platform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: skill-registry
  template:
    spec:
      containers:
      - name: skill-registry
        image: ai-platform/skill-registry:latest
        ports:
        - containerPort: 8084
        env:
        - name: DB_HOST
          value: postgresql.ai-platform
EOF

# 注册基础技能
curl -X POST http://skill-registry.ai-platform:8084/skills \
  -H "Content-Type: application/yaml" \
  -d '
name: track-query
version: 1.0.0
type: mcp_server
endpoint: mcp://tracking-service/query
description: 运单实时状态查询
parameters:
  - name: tracking_number
    type: string
    required: true
'
```

#### 10.4.4 评估服务部署

```bash
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: eval-service
  namespace: ai-platform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: eval-service
  template:
    spec:
      containers:
      - name: eval-service
        image: ai-platform/eval-service:latest
        ports:
        - containerPort: 8085
        env:
        - name: MODEL_GATEWAY_URL
          value: http://model-gateway.ai-platform/v1
        - name: DB_HOST
          value: postgresql.ai-platform
EOF

# 创建首个评估集
curl -X POST http://eval-service.ai-platform:8085/datasets \
  -H "Content-Type: application/json" \
  -d '{
    "name": "logistics-exception-cases",
    "version": 1,
    "industry": "logistics",
    "cases": [{
      "input": {"query": "运单 SF1234567890 延迟了，什么时候到？"},
      "expected": {
        "must_include": ["预计", "延迟原因", "SF1234567890"],
        "must_not_include": ["赔钱", "投诉电话"],
        "action": "track_query"
      }
    }]
  }'
```

#### 10.4.5 Agent 平台层验证检查清单

| # | 检查项 | 验证方法 | 预期 |
|---|--------|---------|------|
| 1 | Agent 运行时健康 | `curl http://agent-runtime:8080/healthz` | 200 |
| 2 | 编排引擎编译 | 创建简单 QA Agent → 运行 | 多步执行无错误 |
| 3 | Checkpoint 断点续执 | 模拟中断 → 重新运行 | 从断点恢复 |
| 4 | 技能注册/调用 | Agent 调用注册技能 | 返回正确结果 |
| 5 | 分层记忆 | 多轮对话 → 检查上下文 | 记忆正确使用 |
| 6 | 评估集运行 | 提交评估集 → 执行 | 返回 Score 报告 |

### 10.5 Phase 4：行业方案接入（Week 9-10）

#### 10.5.1 物流行业包部署

```bash
# 1. 注册物流行业技能
curl -X POST http://skill-registry.ai-platform:8084/skills/batch \
  -H "Content-Type: application/json" \
  -d '[
    {"name":"track-query","version":"1.0.0","type":"mcp_server","endpoint":"mcp://tracking/query","industry":"logistics"},
    {"name":"abnormal-detection","version":"1.0.0","type":"api","endpoint":"http://logistics-api/abnormal/detect","industry":"logistics"},
    {"name":"route-recommend","version":"1.0.0","type":"api","endpoint":"http://logistics-api/route/recommend","industry":"logistics"},
    {"name":"customer-notify","version":"1.0.0","type":"api","endpoint":"http://notify-service/send","industry":"logistics"},
    {"name":"carrier-sla-lookup","version":"1.0.0","type":"api","endpoint":"http://logistics-api/carrier/sla","industry":"logistics"},
    {"name":"weather-query","version":"1.0.0","type":"api","endpoint":"http://weather-api/query","industry":"common"}
  ]'

# 2. 导入物流知识库
curl -X POST http://doc-processor.ai-platform:8081/import \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "logistics-demo",
    "industry": "logistics",
    "files": [
      "s3://ai-platform/knowledge/logistics/sop-transport.md",
      "s3://ai-platform/knowledge/logistics/carrier-contracts.pdf",
      "s3://ai-platform/knowledge/logistics/claims-policy.md"
    ],
    "chunk_strategy": {
      "sop-transport.md": "heading",
      "carrier-contracts.pdf": "clause",
      "claims-policy.md": "heading"
    }
  }'

# 3. 注册物流 Prompt 模板
curl -X POST http://prompt-hub.ai-platform:8083/prompts \
  -H "Content-Type: application/yaml" \
  -d '
id: prompt-logistics-exception-v1
name: 物流异常处理系统提示词
version: 1.0.0
industry: logistics
variables:
  - name: company_name
    source: tenant_config
  - name: sop_context
    source: rag_retrieval
    top_k: 5
model_constraints:
  temperature: 0.3
  max_tokens: 2560
template: |
  你是{{company_name}}的物流异常处理智能助手。
  
  职责:
  1. 识别运输异常类型 (延迟/破损/丢件/地址错误/海关滞留)
  2. 根据 SOP 分级处理: P1(严重)→人工升级, P2(中等)→推荐方案, P3(轻微)→自动处理
  3. 查询承运商 SLA 和合同条款进行责任判定
  4. 涉及赔偿金额>5000元或取消订单时必须人工审批
  
  参考知识(来自SOP/合同):
  {{sop_context}}
  
  处理原则:
  1. 先定位问题根因,再推荐方案
  2. 优先保障客户体验,同时控制成本
  3. 无法100%确定时,标记confidence并建议人工介入
'

# 4. 创建物流异常处理 Agent
curl -X POST http://agent-runtime.ai-platform:8080/agents \
  -H "Content-Type: application/yaml" \
  -d '
apiVersion: agent.platform/v1
kind: Agent
metadata:
  name: logistics-exception-handler
  version: 1.0.0
  industry: logistics
spec:
  model:
    primary: claude-sonnet-4-6
    fallback: deepseek-v3
    temperature: 0.3
    max_tokens: 2560
  prompt:
    ref: prompt-logistics-exception-v1
  skills:
    - ref: track-query
      required: true
    - ref: abnormal-detection
      required: true
    - ref: route-recommend
      required: false
    - ref: customer-notify
      required: false
    - ref: carrier-sla-lookup
      required: false
    - ref: weather-query
      required: false
  knowledge:
    - ref: kb-logistics-sop
      retrieval_top_k: 5
    - ref: kb-carrier-contracts
      retrieval_top_k: 3
  execution:
    max_steps: 10
    timeout: 60s
    human_approval:
      triggers:
        - action: cancel_order
        - amount_gt: 5000
        - confidence_lt: 0.8
  evaluation:
    dataset: logistics-exception-cases
    min_score: 0.85
'
```

#### 10.5.2 行业方案验证检查清单

| # | 检查项 | 验证方法 | 预期 |
|---|--------|---------|------|
| 1 | 物流技能全部注册 | `curl http://skill-registry:8084/skills?industry=logistics` | >=6 个 |
| 2 | 知识库入库 | 查询 Milvus | 有数据 |
| 3 | Prompt 版本可查 | `curl http://prompt-hub:8083/prompts/logistics-exception-v1` | 返回完整定义 |
| 4 | Agent 创建成功 | `curl http://agent-runtime:8080/agents/logistics-exception-handler` | 状态=active |
| 5 | Agent 端到端调用 | 发送测试异常 Query | 多步执行返回结果 |

### 10.6 Phase 5：上线验证（Week 11-12）

#### 10.6.1 端到端集成测试

```python
# test_e2e.py
import pytest
import requests

AGENT_URL = "http://agent-runtime.ai-platform:8080"

@pytest.mark.e2e
class TestLogisticsAgent:
    
    def test_delay_exception_handling(self):
        """延迟异常处理"""
        response = requests.post(f"{AGENT_URL}/agents/logistics-exception-handler/run", json={
            "query": "运单 SF1234567890，原定今天18:00到，但现在是20:00还没到，帮我处理"
        })
        data = response.json()
        assert data["status"] == "completed"
        assert data["steps_count"] >= 3
        assert "track-query" in str(data["skill_calls"])
    
    def test_damage_exception_human_approval(self):
        """破损异常触发人工审批"""
        response = requests.post(f"{AGENT_URL}/agents/logistics-exception-handler/run", json={
            "query": "货物破损严重价值8000元，申请取消订单并退款"
        })
        data = response.json()
        assert any(c["skill"] == "human_approval" for c in data["skill_calls"])
    
    def test_normal_query(self):
        """普通运单查询不触发异常"""
        response = requests.post(f"{AGENT_URL}/agents/logistics-exception-handler/run", json={
            "query": "帮我查一下运单 SF9876543210 到哪了"
        })
        assert "abnormal-detection" not in str(response.json()["skill_calls"])
    
    def test_multi_turn_memory(self):
        """多轮对话记忆"""
        session_id = requests.post(f"{AGENT_URL}/sessions").json()["session_id"]
        r1 = requests.post(f"{AGENT_URL}/agents/logistics-exception-handler/run", json={
            "session_id": session_id,
            "query": "运单 SF1234567890 延迟了"
        })
        r2 = requests.post(f"{AGENT_URL}/agents/logistics-exception-handler/run", json={
            "session_id": session_id,
            "query": "那帮我通知一下客户吧"
        })
        assert "SF1234567890" in str(r2.json()["memory_context"])
```

#### 10.6.2 性能压测

```bash
# k6 压测脚本
cat <<EOF > load-test.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '3m', target: 50 },
    { duration: '5m', target: 100 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    'http_req_duration': ['p95<5000'],
    'http_req_failed': ['rate<0.01'],
  },
};

export default function () {
  const payload = JSON.stringify({
    query: '运单 SF' + Math.random().toString(36).substring(7) + ' 延迟了怎么办？'
  });
  const res = http.post(
    'http://agent-runtime.ai-platform:8080/agents/logistics-exception-handler/run',
    payload,
    { headers: { 'Content-Type': 'application/json' } }
  );
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 10s': (r) => r.timings.duration < 10000,
  });
}
EOF

k6 run load-test.js
```

#### 10.6.3 上线验证检查清单

| # | 检查项 | 通过标准 |
|---|--------|---------|
| 1 | E2E 测试全通过 | 4/4 用例通过 |
| 2 | 评估集 Score | >= 0.85 |
| 3 | P95 延迟 | < 5s |
| 4 | 错误率 | < 1% |
| 5 | Skill 调用准确率 | >= 90% |
| 6 | 语义缓存命中率 | >= 20% |
| 7 | Human-in-the-loop 误触发率 | < 5% |
| 8 | 灰度发布 | 10%→50%→100% 无回滚 |

---

## 11. 物流运输异常处理 Agent — 完整案例

### 11.1 业务场景定义

#### 11.1.1 场景选型

选择**运输异常处理**作为案例，因为它是物流行业最高频、最复杂、涉及系统最多的场景：

```
日均异常处理量 (中型物流企业): 总运单 50,000 单/天 — 正常 47,500 (95%) / 异常 2,500 (5%)。其中延迟 1,200 (48%), 破损 500 (20%), 丢件 300 (12%), 地址错误 250 (10%), 海关滞留 250 (10%)。
```

#### 11.1.2 业务 SOP—人工处理 vs Agent 自动化目标

```
当前人工处理流程 (平均 15 分钟/单):
  客服接到投诉 → 查询运单(TMS,2min) → 判断异常类型(1min)
  → 查询承运商SLA(3min) → 判定责任方(3min) → 制定方案(3min)
  → 联系客户/承运商(3min)

目标: Agent 自动化 → 平均 2 分钟/单, 覆盖 70% 异常单
```

### 11.2 Agent 完整设计

#### 11.2.1 Agent 定义

```yaml
apiVersion: agent.platform/v1
kind: Agent
metadata:
  name: logistics-exception-handler
  version: 1.0.0
  industry: logistics
  owner: operations-team
spec:
  description: >
    运输异常处理 Agent。自动识别延迟、破损、丢件、地址错误、海关滞留五类异常，
    按 P1/P2/P3 分级处理。P1 升级人工，P2 推荐方案+人工确认，
    P3 自动执行。集成 TMS/WMS/OMS/承运商系统/通知系统。
  
  model:
    primary: claude-sonnet-4-6
    fallback: deepseek-v3
    temperature: 0.2
    max_tokens: 3072
  
  prompt:
    ref: prompt-logistics-exception-v1
    
  skills:
    - ref: track-query
      required: true
    - ref: abnormal-detection
      required: true
    - ref: carrier-sla-lookup
      required: true
    - ref: route-recommend
      required: false
    - ref: customer-notify
      required: false
    - ref: carrier-notify
      required: false
    - ref: weather-query
      required: false
    - ref: claim-init
      required: false
    
  knowledge:
    - ref: kb-logistics-sop
      retrieval_top_k: 5
    - ref: kb-carrier-contracts
      retrieval_top_k: 3
    - ref: kb-claims-policy
      retrieval_top_k: 3
    
  memory:
    short_term:
      max_turns: 20
      ttl: 3600
    long_term:
      enabled: true
      scope: tenant
    
  execution:
    max_steps: 10
    timeout: 60s
    human_approval:
      enabled: true
      triggers:
        - action: cancel_order
        - amount_gt: 5000
        - action: initiate_claim
          amount_gt: 1000
        - confidence_lt: 0.75
    
  evaluation:
    dataset: logistics-exception-v1
    min_score: 0.85
    online_eval: true
```

#### 11.2.2 技能清单

| 技能 | 类型 | 端点 | 输入 | 输出 |
|------|------|------|------|------|
| **track-query** | MCP | `mcp://tms/track` | tracking_number | status, location, eta, history |
| **abnormal-detection** | API | `POST /abnormal/detect` | tracking_number | is_abnormal, type, severity, root_cause |
| **carrier-sla-lookup** | API | `GET /carrier/{id}/sla` | carrier_id, route | promised_eta, penalty_clause, compensation_rate |
| **route-recommend** | API | `POST /route/recommend` | from, to, constraints | routes[], estimated_time, cost |
| **customer-notify** | API | `POST /notify/customer` | phone/email, template_id, params | sent, message_id |
| **weather-query** | API | `GET /weather/{location}` | lat, lng | conditions, alerts |
| **claim-init** | API | `POST /claims/initiate` | tracking_number, amount, reason | claim_id, status |

#### 11.2.3 知识库内容结构

**kb-logistics-sop/**: 01-延迟处理流程.md (P1/P2/P3分级SOP) · 02-破损处理流程.md (破损定级+赔偿) · 03-丢件处理流程.md (丢件确认+理赔) · 04-地址错误处理.md (地址修正+改派) · 05-海关滞留处理.md (滞留原因+清关) · 06-客户沟通话术.md (标准话术)

**kb-carrier-contracts/**: 顺丰速运合同_2026.pdf (SLA+赔偿) · 中通快递合同_2026.pdf (SLA+赔偿) · 德邦物流合同_2026.pdf (SLA+赔偿)

**kb-claims-policy/**: 理赔标准流程.md (发起→审核→赔付) · 理赔金额计算规则.md (计算标准) · 理赔时效要求.md (时效要求)

### 11.3 完整调用链路—延迟异常场景

#### 11.3.1 步骤拆解

| Step | 名称 | 调用内容 | 输出 |
|------|------|---------|------|
| 1 | Intent Classify | 模型网关 → `intent_classify` Prompt | type=delay, severity=P2, tracking_no=SF1234567890 |
| 2 | Retrieve Knowledge | 并行: Milvus(SOP) + ES(延迟) + Neo4j(承运商链) | 5段SOP + 3段合同条款 |
| 3 | Recall Memory | Redis (短期记忆) + Milvus (长期记忆) | 本次会话上下文 |
| 4 | LLM Reason #1 | Context = Prompt+SOP+合同+记忆 | TOOL_CALL: track-query(SF1234567890) |
| 5 | Execute Skill #1 | MCP: TMS → `/track` | status=delayed, delayed=4h, eta=明天10:00 |
| 6 | LLM Reason #2 | Context += 运单信息 | TOOL_CALL: carrier-sla-lookup + abnormal-detection |
| 7 | Execute Skills #2 | 并行: SLA查询 + 异常检测 | 赔款30%, 根因=台风 |
| 8 | LLM Reason #3 | 组装最终方案 | 5条方案, confidence=0.92, 需审批(赔款>0) |
| 9 | Human Approval | 推送审批 → 等待 | 人工确认 |
| 10 | Execute Final | customer-notify (短信通知) | sent=true |

### 11.4 数据流转全景

Agent 每步推理前需要消费的数据:

| 数据源 | 用途 | 延迟要求 |
|--------|------|---------|
| **Redis** | Session State (当前会话上下文)、短期记忆、限流计数 | P99 < 2ms |
| **Milvus** | 知识检索 (SOP/合同/政策)、长期记忆 (历史相似Case) | P99 < 10ms |
| **Neo4j** | 承运商关系链查询、物流网络拓扑查询 | P99 < 15ms |
| **Elasticsearch** | 关键词精确匹配、模糊搜索 | P99 < 20ms |
| **PostgreSQL** | Agent定义/版本、Skill注册、Prompt版本、评估集、租户配置 | P99 < 5ms |

Agent 运行中触发的主要写入操作:

| 写入目标 | 内容 | 保留策略 |
|---------|------|---------|
| **Kafka** | Agent状态变更、模型调用日志、审计日志 | 7天 / 90天 / 7年 |
| **Redis** | Session State (会话状态) | TTL: 会话+30min |
| **PostgreSQL** | 对话记录、决策记录、审计日志 | 365天 / 永久 / 7年 |
| **Milvus** | 重要决策 (长期记忆) | 永久 |

### 11.5 端到端数据流示例

以 "运单 SF1234567890 延迟" 完整展示:

```
用户输入: "运单SF1234567890延迟了，客户说已经晚4小时了，帮我处理"

→ Intent Classify:
   {intent: "exception_handling", exception_type: "delay",
    severity: "P2", tracking_number: "SF1234567890"}

→ Knowledge Retrieval (并行):
   Milvus: SOP§P2延迟处理 (score=0.94), 延迟分级标准 (0.89)
   ES: 顺丰合同§5.3延迟赔偿 (BM25=8.2)
   Neo4j: 承运商=顺丰速运, SLA=24h, penalty=30%

→ LLM Reason #1 → TOOL_CALL: track-query(SF1234567890)
   → {status: delayed, delayed: 4h15m, location: "杭州中转",
      eta: "2026-05-15 10:00", weather_alert: "台风预警"}

→ LLM Reason #2 → TOOL_CALL: abnormal-detection + carrier-sla-lookup
   → abnormal: {root_cause: "台风'艾云尼'影响杭州段封路", confidence: 0.95}
   → SLA: {promised: 24h, actual: 28h+, penalty: "运费30%", max: 200元}

→ LLM Reason #3 → 组装方案:
   summary: "运单SF1234567890因台风延迟4h15min"
   recommendations: [通知客户, 无需改路线, 赔偿运费30%≈45元]
   confidence: 0.93, needs_approval: true

→ Human Approval → 通过

→ customer-notify:
   "【XX物流】您的快件SF1234567890因台风影响延迟约4小时,
    预计明日10:00送达,将赔偿运费30%,给您带来不便敬请谅解。"

最终输出:
  {status: "completed", steps_count: 8, skills_called: 4,
   confidence: 0.93, duration_ms: 4230,
   token_usage: {prompt: 2450, completion: 680}}
```

### 11.6 多 Agent 协作—复合异常

同一案例涉及延迟+破损时，触发 Hierarchical 多 Agent 协作:

**Hierarchical 协作模式:** Supervisor Agent (复合异常: "延迟+破损") → 分派给 Delay Specialist (查询延迟SOP/查询SLA/建议赔偿) + Damage Specialist (查询破损SOP/查询理赔政策/计算赔偿) → Aggregator Agent 合并结果 ("延迟赔30%+破损赔50%=总赔")

---

## 12. Agent 执行准确率提升体系

### 12.1 准确率定义与度量

#### 12.1.1 五维度复合指标

| 维度 | 度量方法 | 目标 | 数据来源 |
|------|---------|------|---------|
| **P1: 意图识别准确率** | 分类正确数 / 总请求数 | ≥95% | LLM-as-Judge + 人工抽检(5%) |
| **P2: 知识检索准确率** | Recall@5 = Top-5相关文档数 / 总相关文档数 | ≥90% | 人工标注金标数据集 |
| **P3: Skill调用准确率** | 正确(Skill+参数)数 / 总调用数 | ≥92% | 自动校验(参数Schema) + 人工抽检 |
| **P4: 推理质量准确率** | 综合 Score (准确性+有用性+安全性) | ≥85% | LLM-as-Judge + 用户反馈 |
| **P5: 端到端成功率** | 无需人工介入完成数 / 总任务数 | ≥80% | Kafka事件流 + 审批触发日志 |

![Agent 执行准确率五维模型与90天提升路径](images/fw-arch-18-accuracy-model.png)

### 12.2 Prompt 工程体系

#### 12.2.1 Prompt 分层架构

- **Layer 1: Base Prompt (平台级, 不可被租户覆盖)** — 通用安全约束, 通用行为规范, 模型约束默认值
- **Layer 2: Industry Prompt (行业级)** — 术语定义, 行业规则, 异常分级标准
- **Layer 3: Agent Prompt (Agent 级)** — 具体场景定义, Skill 调用策略, 业务规则
- **Layer 4: Tenant Override (租户定制, 可选)** — 企业特定规则, 品牌语气调整, 自定义 SOP 引用

#### 12.2.2 三大优化方法

**方法一: Few-Shot 示例注入** — 在 System Prompt 中注入 3-5 个高质量处理示例,引导 LLM 行为模式

**方法二: Chain-of-Thought 强制推理链** — 要求 LLM 按固定步骤推理 (信息提取→数据获取→知识检索→判定推荐→输出)

**方法三: A/B 测试框架** — 对同一评估集跑两个 Prompt 版本,输出五维度对比报告+显著性检验

#### 12.2.3 Prompt 回归测试 CI/CD

```
每次 Prompt 变更 → 自动触发:
  Step 1: 跑评估集 (准确性+安全性+格式+回归对比)
  Step 2: 对比报告:
    Score下降>5% → ❌ 阻断
    Score波动<5% → ⚠️ 人工审核
    Score上升 → ✅ 自动合并
  Step 3: 灰度发布 (10%→50%→100%)
```

### 12.3 RAG 检索质量提升

#### 12.3.1 五步法

| # | 抓手 | 方案 | 效果 |
|---|------|------|------|
| ① | Query 改写 | HyDE(假设文档嵌入)+术语扩展+多轮上下文补全 | Recall@5 +15-20% |
| ② | 混合检索 | Milvus向量+ES关键词+Neo4j图三路召回 | Recall@5 +10-15% |
| ③ | 分块策略优化 | 文档类型感知分块 (见第4章分块策略矩阵) | Chunk相关度 +20% |
| ④ | Rerank精排 | Cross-Encoder对Top-20精排→Top-5 | Precision@5 +25-35% |
| ⑤ | 知识库治理 | 文档版本管理+时效标记+定期清理 | 错误率 -30-50% |

#### 12.3.2 核心实现

```python
# Query 改写 — 多策略扩展
class QueryRewriter:
    async def rewrite(self, query, context) -> List[str]:
        queries = [query]  # 原始Query
        # 策略1: HyDE — 生成假设答案替代Query
        hyde = await self.llm.generate("根据问题生成可能的答案...")
        queries.append(hyde)
        # 策略2: 术语扩展 — "快递"→"快递/快件/包裹/运单"
        expanded = await self.llm.generate("替换为物流术语...")
        queries.extend(expanded.split("\n"))
        # 策略3: 多轮上下文补全 — "那这个呢?"→完整独立问题
        if context.get("history"):
            completed = await self.llm.generate("改写为独立完整问题...")
            queries.append(completed)
        return queries[:5]
```

```python
# Rerank — Cross-Encoder精排 + MMR多样性去重
class Reranker:
    async def rerank(self, query, candidates, top_k=5):
        # Step 1: Cross-Encoder打分
        pairs = [(query, doc.content) for doc in candidates]
        scores = self.cross_encoder.predict(pairs)
        # Step 2: 时效加权 — 7天内文档+0.1
        # Step 3: MMR多样性去重 — λ=0.7平衡相关性和多样性
        ...
        return selected[:top_k]
```

### 12.4 Skill 路由准确性提升

#### 12.4.1 错误类型分布

| 错误类型 | 占比 | 示例 |
|---------|------|------|
| 遗漏调用(该调没调) | 40% | 应该查SLA但直接下结论 |
| 多余调用(不该调乱调) | 15% | 简单查询却调用理赔Skill |
| 参数错误(调了但参数错) | 25% | 用客户名当运单号查询 |
| Skill混淆(选了相似但错的) | 10% | 调了route-recommend而非abnormal-detection |
| 顺序错误(调了但时机错) | 10% | 先通知客户再查SLA |

#### 12.4.2 三大提升方案

**方案一: Skill Description 优化** — 结构化+触发条件+反例+依赖声明
**方案二: Skill Validator** — LLM选择Skill后在调用前验证:必填参数完整性/依赖Skill已执行/参数类型校验
**方案三: 历史纠错学习** — 人工纠正→写入long-term memory→检索相似Case的Few-Shot

### 12.5 多 Agent 协作可靠性

- **协作模式自动选择**: 单领域→Sequential; 多领域独立→Router; 多领域相互依赖→Hierarchical; 高风险→Debate
- **Supervisor 幻觉防护**: 分配→并行执行→交叉验证(confidence<0.7重新分配)→冲突检测→汇总

### 12.6 Human-in-the-Loop 机制

#### 12.6.1 审批触发维度

| 维度 | 触发规则 |
|------|---------|
| 操作类型 | cancel_order→始终审批; initiate_claim→金额>1000审批 |
| 金额 | >5000元→审批 |
| 置信度 | <0.75→审批; <0.85+涉及赔偿→审批 |
| 异常等级 | P1→始终审批; P2+涉及赔偿→审批 |
| 客户等级 | VIP→所有操作审批; 大客户→涉及金额审批 |

#### 12.6.2 审批反馈闭环

人工审批不仅是"通过/驳回",更是 Agent 学习的信号。每次人工驳回都记录为 training_example,包括原始Query、Agent错误输出、人工修正、纠错类型。每周聚合分析高频纠错类型,针对性优化Prompt/Skill描述/知识库。

### 12.7 评估反馈闭环

```
离线评估(发布前必过) → 灰度发布(10%→50%→100%)
  → 在线监控(实时指标+异常告警)
  → 用户反馈收集(👍👎+纠错)
  → 自动/半自动优化 → 回到离线评估
```

### 12.8 实战提升路径（90天计划）

```
Week 1-2: 建立基线 — 评估服务+首个数据集+基线Score+在线监控
Week 3-4: Prompt优化 — Few-Shot+CoT+A/B测试+回归CI/CD → P1+P4 +5-10%
Week 5-6: RAG质量 — Query改写+Rerank+分块策略+知识库清理 → P2 +15-20%
Week 7-8: Skill路由 — Description重写+Validator+纠错Few-Shot → P3 +10-15%
Week 9-10: 端到端 — HITL触发调优+多Agent协作+灰度+压测 → P5 +15-20%
Week 11-12: 持续优化 — 评估集自动进化+每周纠错分析+知识库自动补充
```

#### 12.8.1 准确率提升效果预估

```
五维度 Score 提升预估:

          Day 1     Week 4    Week 8    Week 12   目标
| 维度 | Day 1 | Week 4 | Week 8 | Week 12 | 目标 |
|------|-------|--------|--------|---------|------|
| P1 意图 | 0.88 | 0.92 | 0.94 | 0.96 | ≥0.95 ✅ |
| P2 检索 | 0.70 | 0.80 | 0.87 | 0.91 | ≥0.90 ✅ |
| P3 Skill | 0.78 | 0.84 | 0.90 | 0.93 | ≥0.92 ✅ |
| P4 推理 | 0.72 | 0.78 | 0.83 | 0.87 | ≥0.85 ✅ |
| P5 端到端 | 0.65 | 0.72 | 0.78 | 0.83 | ≥0.80 ✅ |
| **综合** | **0.75** | **0.81** | **0.86** | **0.90** | **≥0.88** |
```

---

---

## 13. Java 技术栈集成方案

### 13.1 核心矛盾与选型

企业后端以 Java/Spring Boot 为主力技术栈，而 AI Agent 引擎的最佳实践在 Python 生态（LangGraph/LlamaIndex/OpenAI SDK/vLLM 客户端等）。方案选择：**独立 Agent 服务 + API 网关调用**（方案 A），语言解耦、独立扩缩容、Python AI 生态不受限。

### 13.2 整体集成架构

**集成方式：独立 Agent 服务 + API 网关调用**

- **Java 后端 (Spring Boot)** — 通过 HTTP/gRPC 调用 Agent 服务（`POST /agent/run`、`GET /agent/{id}`）
- **Agent 服务 (Python)** — LangGraph 编排引擎 + 模型网关 + RAG + 技能执行 + 分层记忆
- **Higress Gateway** — 统一流量入口，负责限流、Prompt Injection 检测、灰度发布

**完整请求链路：**

用户 → Java 后端 (鉴权 + 业务上下文注入) → Higress Gateway (限流 + Prompt Injection 检测 + 灰度) → Agent Router (意图分类 → 决策路由) → Agent 服务 Python (LangGraph 编排) → Java 后端 (格式化 → 审计 → 返回前端)

### 13.3 Java 后端集成实现

```java
// AgentClient.java — Spring Boot 中调用 Agent 服务
@Service
public class AgentClient {
    
    private final RestClient restClient;
    
    public AgentClient(@Value("${agent.service.url}") String agentUrl) {
        this.restClient = RestClient.builder()
            .baseUrl(agentUrl)
            .defaultHeader("X-Tenant-Id", TenantContext.getCurrent())
            .build();
    }
    
    /**
     * 同步调用 Agent (适用于低延迟场景)
     */
    public AgentResponse runAgent(String agentId, String query, String sessionId) {
        return restClient.post()
            .uri("/agents/{agentId}/run", agentId)
            .body(Map.of(
                "query", query,
                "session_id", sessionId,
                "context", Map.of(
                    "tenant_id", TenantContext.getCurrent(),
                    "user_id", SecurityContext.getCurrentUser(),
                    "user_tier", getUserTier()  // VIP/普通, 影响 HITL 策略
                )
            ))
            .retrieve()
            .body(AgentResponse.class);
    }
    
    /**
     * 异步调用 Agent + Webhook 回调 (适用于长时间 Agent 任务)
     */
    public void runAgentAsync(String agentId, String query, 
                               String sessionId, String callbackUrl) {
        restClient.post()
            .uri("/agents/{agentId}/run-async", agentId)
            .body(Map.of(
                "query", query,
                "session_id", sessionId,
                "callback_url", callbackUrl
            ))
            .retrieve()
            .toBodilessEntity();
    }
}

// AgentResponse.java — 统一返回体
public record AgentResponse(
    String status,           // completed | pending_approval | failed
    int stepsCount,
    List<SkillCall> skillsCalled,
    String response,
    Double confidence,
    Long durationMs,
    TokenUsage tokenUsage
) {}

// 业务层调用示例
@Service
public class ExceptionHandlingService {
    
    private final AgentClient agentClient;
    
    public HandleResult handleException(ShipmentException exception) {
        var response = agentClient.runAgent(
            "logistics-exception-handler",
            exception.toAgentQuery(),
            exception.getSessionId()
        );
        
        if ("pending_approval".equals(response.status())) {
            // 推送审批到 OA/飞书
            approvalService.push(response);
            return HandleResult.pending(response);
        }
        
        // 记录审计
        auditLog.record(exception.getTrackingNo(), response);
        return HandleResult.completed(response);
    }
}
```

### 13.4 跨 Agent 通信——Higress 网关接入

#### 13.4.1 Higress 适配分析

Higress (阿里开源 API 网关，基于 Istio+Envoy) 在 Agent 架构中的两层定位：

| 通信层 | 协议 | Higress 是否接管 | 说明 |
|--------|------|:---:|------|
| **平台内 Agent 编排** | LangGraph StateGraph | ❌ 不适用 | 进程内 Python 函数调用，不经过网络 |
| **跨 Agent 服务通信** | A2A (Google) / MCP (Anthropic) / gRPC | ✅ 可以 | 走 HTTP/RPC 流量，Higress 全链路管理 |
| **Java → Agent 服务** | REST/gRPC | ✅ 可以 | 统一流量入口 |

#### 13.4.2 Higress 在 Agent 平台中的具体应用

| Higress 能力 | Agent 平台应用 |
|-------------|---------------|
| **流量路由** | `/agents/{id}/run` → 路由到正确的 Agent 服务 Pod |
| **灰度发布** | Agent V2.0 上线: 10%→50%→100% 分阶段切流，按 tenant_id 哈希保证同一租户请求一致性 |
| **限流保护** | 按租户+Agent 双维度 Token Bucket，防止单租户打爆推理服务 |
| **Wasm 安全插件** | 自定义 Wasm: Prompt Injection 检测、敏感信息脱敏——在网关层拦截，不进 Agent 服务 |
| **认证鉴权** | OIDC/OAuth 2.0 统一认证，Agent 服务无需重复鉴权 |
| **可观测性** | 与 SkyWalking/Prometheus 集成，Agent 调用链路全追踪 |

#### 13.4.3 Higress 路由配置

```yaml
# Higress Wasm 插件: Agent Prompt Injection 检测
apiVersion: extensions.higress.io/v1alpha1
kind: WasmPlugin
metadata:
  name: agent-security-filter
  namespace: higress-system
spec:
  url: oci://registry.example.com/wasm/agent-security:1.0
  phase: AUTHN  # 认证阶段执行
  matchRules:
    - config:
        block_patterns:
          - "忽略(所有|之前|上面).*(指令|规则|限制)"
          - "ignore.*(previous|above).*instructions"
          - "DAN.*mode"
          - "jailbreak"
      ingress:
        - agent-service
```

```yaml
# Higress 灰度路由: Agent V2.0 按租户比例切流
apiVersion: networking.higress.io/v1
kind: HttpRoute
metadata:
  name: agent-canary
spec:
  rules:
  - matches:
    - path:
        type: Exact
        value: /agents/logistics-exception-handler/run
    backendRefs:
    - name: agent-v1-stable
      port: 8080
      weight: 90
    - name: agent-v2-canary
      port: 8080
      weight: 10
```

### 13.5 Agent Router：Agent 网关与两层决策模型

#### 13.5.1 Agent Router 的定位——是 Agent 网关，不是业务网关

Agent Router 本质上是一个 **Agent 网关**——它不决定"这个请求是不是要走 Agent"，只决定"走哪个 Agent"。

"是不是要走 Agent"这个决定在更上游就做出了：

```
请求进来:

  Higress Gateway (统一入口)
      │
      ├── /api/orders/list       → Java 后端 → 直接查数据库返回 (不走 Agent)
      ├── /api/orders/create     → Java 后端 → 业务逻辑处理 (不走 Agent)
      ├── /api/shipment/track    → Java 后端 → 调 TMS API 返回 (不走 Agent)
      │
      └── /api/exception/handle  → Java 后端 → 判断"这个需要 AI 处理"
                                       │
                                       ▼
                                  AgentClient.runAgent(...)
                                       │
                                       ▼
                                  Agent Router (Agent 网关)
                                       │
                                  "这是异常处理 → logistics-exception-handler"
```

**两层路由的分工：**

| 在哪层 | 谁决定 | 决定什么 | 依据 |
|--------|--------|---------|------|
| **Higress** | URL 路径匹配 | 这个请求发给 Java 后端还是直接发给 Agent 服务？ | `/api/*` → Java 后端；`/agents/*` → Agent Router（如果外部直接调 Agent API） |
| **Java 后端** | 业务代码 | 这个业务操作需不需要调用 AI？ | 业务逻辑判断——异常处理需要 AI，查列表不需要 |
| **Agent Router** | 意图分类模型 | 需要哪个 Agent 来处理？ | 用户 Query 的语义 + 可用 Agent 列表 |

**所以 Agent Router 管的是 Agent 之间的路由（哪个 Agent），不管业务请求和 Agent 请求的分流。分流是 Java 后端在业务代码里做的。**

#### 13.5.2 决策位置

Agent Router 在 Higress Gateway 之后、Agent 编排引擎之前：

```
用户请求 → Java后端(鉴权) → Higress(安全+限流) → Agent Router(决策) → Agent编排引擎(执行)
```

#### 13.5.3 两层决策模型

| 层级 | 负责 | 输入 | 输出 |
|------|------|------|------|
| **Layer 1: 意图路由** | 决策"调用哪个 Agent" | 用户 Query + 可用 Agent 列表 | target_agent, confidence, extracted_slots |
| **Layer 2: 编排路由** | Agent 内部"怎么执行" | Agent 状态 | 下一步: call_skill / need_approval / respond |

Layer 1 在 Agent Router 中完成，调用模型网关做意图分类。Layer 2 由 LangGraph StateGraph 的 `conditional_edges` 完成。

```python
class AgentRouter:
    """Agent Router — 决策调用哪个 Agent"""
    
    def __init__(self, model_gateway, agent_registry):
        self.model_gateway = model_gateway
        self.agent_registry = agent_registry
    
    async def route(self, user_query: str, tenant_id: str, user_context: dict) -> RouteDecision:
        # Step 1: 模型做意图分类 (Prompt: prompt-agent-router-v1)
        intent = await self.model_gateway.classify(
            prompt_ref="prompt-agent-router-v1",
            variables={
                "user_query": user_query,
                "available_agents": self.agent_registry.list_active(tenant_id),
            }
        )
        # Step 2: 规则校验 (确定性)
        rule_result = self._validate_with_rules(intent, tenant_id)
        # Step 3: 综合置信度
        final_confidence = intent["confidence"] * rule_result["multiplier"]
        # Step 4: 决策
        if final_confidence < 0.7:
            return RouteDecision(agent="general-assistant", 
                                 fallback_reason=rule_result["checks"])
        return RouteDecision(agent=intent["target_agent"], 
                             confidence=final_confidence,
                             extracted_slots=intent["extracted_slots"])
    
    def _validate_with_rules(self, intent, tenant_id):
        """规则校验——确定性的，不依赖模型"""
        checks = []
        multiplier = 1.0
        
        # 校验: Agent 是否存在且激活
        if intent["target_agent"] not in self.agent_registry.list_active(tenant_id):
            return {"multiplier": 0, "checks": ["agent_not_found"]}
        
        agent = self.agent_registry.get(intent["target_agent"])
        
        # 校验: 行业匹配
        tenant = self.agent_registry.get_tenant(tenant_id)
        if agent.industry != tenant.industry and not agent.cross_industry:
            multiplier = min(multiplier, 0.5)
            checks.append("industry_mismatch")
        
        # 校验: 必填槽位完整性
        for slot in agent.required_slots:
            if slot not in intent.get("extracted_slots", {}):
                multiplier = min(multiplier, 0.6)
                checks.append(f"missing_slot:{slot}")
        
        return {"multiplier": multiplier, "checks": checks}
```

#### 13.5.4 置信度判定：双通道机制

**通道一：模型 self-confidence（语义匹配——模糊判断）**

模型在推理时通过 Prompt 要求输出 `confidence` 字段，基于训练数据对"我有多确定"的自我评估：

```yaml
# prompt-agent-router-v1
template: |
  你是一个 Agent 路由器。根据用户输入判断应路由到哪个 Agent。
  可用 Agent: {{available_agents}}
  
  返回 JSON: {
    "target_agent": "<name>",
    "confidence": <0.0-1.0>,  # 你的确信程度
    "intent": "<type>",
    "extracted_slots": {...},
    "reasoning": "<理由>"
  }
  
  confidence 标准:
  - 0.9-1.0: 明确匹配
  - 0.7-0.9: 基本匹配但有些模糊
  - 0.5-0.7: 不太确定，可能跨多个 Agent
  - <0.5: 无法确定
  
  用户输入: {{user_query}}
```

**通道二：规则校验（事实核查——确定性判断）**

代码层做确定性校验，不依赖模型判断：

| 校验项 | 失败后果 | 类型 |
|--------|---------|------|
| Agent 是否存在于当前租户 | confidence → 0 | 阻断 |
| 行业是否匹配 | confidence × 0.5 | 降权 |
| 必填槽位是否提取完整 | confidence × 0.6 | 降权 |
| Agent 是否在维护期 | confidence × 0.3 | 降权 |
| 租户额度是否耗尽 | confidence → 0 | 阻断 |

**综合判定:**

```
final_confidence = model_confidence × rule_multiplier

≥ 0.85 → 直接路由到目标 Agent
0.70-0.85 → 路由但标记 low_confidence，Agent 内部 HITL 阈值下调
< 0.70 → 降级到 general-assistant 或人工
= 0 → 阻断，返回友好提示
```

#### 13.5.4 完整路由示例

```
输入: "运单SF123延迟了，客户催，帮我处理"

Step 1 — 模型分类:
  → {target_agent: "logistics-exception-handler", confidence: 0.92,
     extracted_slots: {tracking_number: "SF123", exception_type: "delay"}}

Step 2 — 规则校验:
  ✅ Agent 存在 → multiplier 1.0
  ✅ 行业匹配 (logistics=logistics) → multiplier 1.0
  ✅ 必填槽位 tracking_number 已提取 → multiplier 1.0
  → rule_multiplier = 1.0

Step 3 — 综合: 0.92 × 1.0 = 0.92 ≥ 0.85 → 直接路由

输入: "帮我查个事"  # 模糊输入

Step 1 — 模型分类:
  → {target_agent: "logistics-exception-handler", confidence: 0.45,
     extracted_slots: {}}

Step 2 — 规则校验:
  ❌ 必填槽位 tracking_number 缺失 → multiplier 0.6

Step 3 — 综合: 0.45 × 0.6 = 0.27 < 0.70 → 降级到 general-assistant
```

---

---

## 14. Prompt Hub 独立服务设计

### 14.1 定位与边界

Prompt Hub 是 AI 能力层的独立服务，与模型网关、RAG 引擎同级部署。它不是 Agent Runtime 的内置配置模块，而是一个**集中管理 Prompt 版本、继承、变量和回归测试的生命周期服务**。

### 14.2 调用时机

Prompt Hub 在两个阶段被调用：

**阶段一：配置期（Agent 创建/更新时）**

```
开发者 → Admin UI → Prompt Hub API
  · 创建 Prompt 模板 (POST /prompts)
  · 版本管理 (Draft → Review → A/B Test → Published → Deprecated)
  · 设置继承关系 (Base → Industry → Agent)
  · 配置 A/B 测试 (指定评估集 + 流量比例)
  · 回滚到历史版本
```

**阶段二：推理期（Agent 运行时，每次 LLM 推理前）**

```
Orchestration Engine (Step 4: LLM Reason)
    │
    ├── ① POST /prompts/resolve
    │      {ref: "prompt-logistics-exception-v1",
    │       variables: {company_name: "XX物流", ...}}
    │      → Prompt Hub 返回: 填充后的完整 System Prompt (纯文本)
    │
    ├── ② POST /retriever/search (并行 → RAG Engine)
    │      → 返回: Knowledge Context
    │
    ├── ③ Redis/Milvus (并行 → Memory Store)
    │      → 返回: Memory Context
    │
    └── ④ 拼入 Context Window:
           [System Prompt] ← Prompt Hub 返回
           [Knowledge]     ← RAG 返回
           [Memory]        ← Memory Store 返回
           [History + User Message]
                    ↓
           POST /v1/chat/completions → Model Gateway → LLM
```

### 14.3 独立服务的理由

| 如果内置在 Agent Runtime | 独立 Prompt Hub 服务 |
|---|---|
| Prompt 版本更新需重启 Agent 服务 | 热更新，零停机 |
| A/B 测试需在代码里写逻辑 | 集中管理，路由层决定用哪个版本 |
| 多个 Agent 共享 Prompt 模板时各自维护 | 继承机制 (Base→Industry→Agent)，一处改全局生效 |
| 回归测试需手动触发 | 发布前自动触发评估集跑分，不通过阻断发布 |
| Prompt 修改无审计记录 | 每次变更记入审计日志 |

### 14.4 Prompt 解析 API

```python
# Prompt Hub 核心接口
class PromptHub:
    
    async def resolve(
        self, 
        ref: str,           # 如 "prompt-logistics-exception-v1"
        variables: dict     # 如 {company_name: "XX物流", ...}
    ) -> str:
        """解析 Prompt 引用，填充变量，返回完整 System Prompt"""
        
        # Step 1: 从 PG 拉取当前生效版本
        prompt = await self.db.get_prompt(ref)
        
        # Step 2: 如果设了 base，递归解析继承链
        #   如: logistics-exception → logistics-base → platform-base
        base_content = ""
        if prompt.base_ref:
            base_content = await self.resolve(prompt.base_ref, variables)
        
        # Step 3: 填充变量 ({{company_name}} → "XX物流")
        filled = prompt.template
        for name, value in variables.items():
            filled = filled.replace(f"{{{{{name}}}}}", str(value))
        
        # Step 4: 合并 (base + agent level)
        return self._merge(base_content, filled)
```

### 14.5 在调用链路中的位置

```
Orchestration Engine (编排引擎)
    │
    │  Step 4: LLM Reason — 每次推理前:
    │
    ├── Prompt Hub      → System Prompt (角色+规则+任务)
    ├── RAG Engine      → Knowledge Context (SOP/合同/政策原文)
    ├── Memory Store    → Memory Context (对话历史+用户偏好)
    │
    └── 组装 Context Window → Model Gateway → LLM
```

---

## 15. 知识向量与原文存储关系

### 15.1 核心矛盾

有了知识库向量（Milvus），为什么还要存知识原文（MinIO/S3）？

**向量是索引，不是内容。** 类比一本书——书后的关键词索引页告诉你"第 42 页提到了延迟处理"，但你不能只看索引就知道第 42 页写了什么具体内容。你最终需要翻到第 42 页读原文。

### 15.2 两者分工

```
检索阶段 (用向量)                    组装阶段 (用原文)
┌──────────────────┐            ┌──────────────────┐
│ Query → Embedding│            │ Milvus 返回:      │
│ → Milvus 搜索     │            │  doc_id="sop-01", │
│ → 返回: doc_id,  │ ─────────►│ chunk_index=3,    │
│    chunk_index,   │            │ score=0.94        │
│    similarity     │            │                   │
└──────────────────┘            │ 用 doc_id 去 MinIO │
                                 │ 拉原文:            │
                                 │ sop-transport.md   │
                                 │ → 第3段 = "P2级    │
                                 │ 延迟处理流程..."   │
                                 │       ↓           │
                                 │ 拼入 LLM Context   │
                                 └──────────────────┘
```

### 15.3 各存储各存什么

| 存储 | 存什么 | 举例 | 用途 |
|------|--------|------|------|
| **Milvus (向量库)** | Embedding 向量 + `{doc_id, chunk_index, metadata}` | `[0.23, -0.41, ...]` → `sop-transport.md#chunk-3` | **检索**——找到"哪些文档相关" |
| **MinIO/S3 (对象存储)** | 原始文档全文 | `sop-transport.md` 全文 / `顺丰合同.pdf` 全文 | **组装**——拿到完整原文拼入 LLM Context Window |
| **Redis** | 不存知识原文 | 存高频检索缓存和推导结果 | 缓存提速 |
| **PostgreSQL** | 不存知识原文 | 存文档元数据 (filename, version, updated_at, chunk_count) | 文档管理 |

### 15.4 为什么不能只存向量

1. **LLM 最终需要原文，不是向量** — 你不可能给 LLM 喂 `[0.23, -0.41, 0.87, ...]`
2. **向量有损压缩** — Embedding 丢失了细节，同一个向量可能对应不同原文
3. **原文需要审计和回溯** — "Agent 为什么这么回答？" → 查引用原文 → 对象存储拉取
4. **原文需要被更新** — SOP 改了版本，对象存储覆盖原文，触发 Milvus 重建索引，但向量本身无法"编辑"
5. **Rerank 需要原文** — Cross-Encoder 精排必须用原文做语义匹配，向量相似度只做粗筛

### 15.5 检索→组装→审计完整链路

```
用户: "运输延迟了怎么赔？"

Step 1: Embedding Service → Query Vector
Step 2: Milvus.search() → [{doc_id:"sop-01", chunk:3, score:0.94}, ...]
Step 3: Rerank (Cross-Encoder) → Top-5 确定
Step 4: MinIO 拉原文 → sop-transport.md 第3段全文
Step 5: 拼入 LLM Context Window → 推理
Step 6: 审计回溯 → 查询 PG 中的 reference 记录 → 再次从 MinIO 拉原文确认
```

---

## 16. 会话三层存储原理与 Recall 决策逻辑

### 16.1 三种存储各存什么

同一会话的数据被拆成三层存储，各管各的，不存在冗余：

| 存储 | 存什么 | 谁用 | 速度 | 任期 |
|------|--------|------|------|------|
| **Redis (会话缓存)** | 当前会话原文（最近20轮对话+skill执行结果） | LLM 构建 Context Window，每次推理必读 | P99 < 2ms | 会话结束+30min 销毁 |
| **PostgreSQL (会话原文)** | 所有会话完整原文（当前+历史），按 step 逐条存储 | 审计/回溯/合规查询、新会话从历史续接 | P99 < 5ms | 365天 |
| **Milvus (会话向量索引)** | 只有向量索引 + `{session_id, step_id}` 指针 | 长期记忆检索，找到"哪些历史对话可能相关" | P99 < 10ms | 永久 |

### 16.2 为什么不能只存一种

- **只存 Redis** → 会话结束数据丢失，无法审计，无法跨会话回忆
- **只存 PG** → 每次构建 Context Window 查 SQL，延迟累积（每秒10+次推理的场景无法接受）
- **只存 Milvus 向量** → 向量无法还原原文，审计不了，也无法给 LLM 喂真实的对话历史

### 16.3 写入路径（Agent 运行中并行写入）

```
Agent 每步执行完成:

  ├──→ Kafka (事件流: step_completed, 异步解耦)
  │
  ├──→ Redis (同步写，缓存当前会话原文)
  │     key: session:{id}:context
  │     value: [{role:"user", content:"..."}, {role:"agent", content:"..."}, ...]
  │     lpush 最新一轮, ltrim 保留最近20轮
  │     TTL: 会话结束+30min
  │
  ├──→ PostgreSQL (同步写，持久化完整原文)
  │     INSERT INTO conversations (session_id, step, role, content, timestamp)
  │     VALUES ('sess-042', 5, 'agent', '延迟4h, 根因=台风...', NOW())
  │     retention: 365天
  │
  └──→ Milvus (仅重要步骤写向量索引，非每步都写)
        · 决策点（如 Agent 最终方案输出）→ 写
        · 中间步骤（如 track-query 结果）→ 不写
        存: {embedding, session_id, step_id}
        不存: 对话原文
```

### 16.4 读取路径——Recall 决策逻辑

记忆读取在编排引擎的 `recall` 节点中完成，**不是二选一，而是逐层获取**：

```python
class RecallNode:
    """编排引擎 Step 3: Recall Memory"""
    
    async def recall(self, state: AgentState) -> AgentState:
        
        # ① 读 Redis (每次都读，P99 < 2ms，开销极低)
        redis_context = await self.redis.get_session_context(state.session_id)
        # 拿到当前会话最近 20 轮原文
        state["memory_context"] = redis_context["messages"][-20:]
        
        # ② 判断是否读 PG (按需，三种触发条件)
        should_fetch_history = (
            self._is_new_session(state)                # 全新会话，需接续上轮
            or self._has_cross_session_intent(state)    # "上次那个延迟单..."
            or self._context_insufficient(state)        # LLM判断上下文不够
        )
        
        if should_fetch_history:
            # ②a: Milvus 语义搜索 → 拿到 {session_id, step_id, similarity}
            hits = await self.milvus.search(
                collection="long_term_memory",
                vector=await self.embed(state["user_query"]),
                top_k=3
            )
            
            # ②b: 用 session_id + step_id 去 PG 拿原文
            for hit in hits:
                content = await self.pg.query("""
                    SELECT content FROM conversations
                    WHERE session_id = ? AND step_id = ?
                """, (hit["session_id"], hit["step_id"]))
                
                state["long_term_context"].append({
                    "content": content,
                    "similarity": hit["similarity"]
                })
        
        # ②c: 如果是全新会话但同一用户 → 从 PG 取上轮最后10轮接续
        if self._is_new_session(state):
            prev_session = await self.pg.get_last_session(state.user_id)
            if prev_session:
                state["memory_context"].extend(
                    prev_session["messages"][-10:]
                )
        
        return state
    
    def _is_new_session(self, state) -> bool:
        """当前会话 Redis 为空，是全新会话"""
        return len(state.get("memory_context", [])) == 0
    
    def _has_cross_session_intent(self, state) -> bool:
        """用户 Query 触发了跨会话回忆意图"""
        cross_session_keywords = [
            "上次", "之前", "上一次", "那天", "前两天",
            "上次那个", "跟上次一样", "还是一样的"
        ]
        query = state["user_query"]
        return any(kw in query for kw in cross_session_keywords)
    
    def _context_insufficient(self, state) -> bool:
        """LLM 判断当前上下文是否足够"""
        # 在 LLM Reason 中设置标记:
        # if current_confidence < 0.7:
        #     state["context_insufficient"] = True
        return state.get("context_insufficient", False)
```

### 16.5 不读 PG 的情况

| 场景 | 原因 |
|------|------|
| Redis 已有充足上下文 (最近20轮) | 开销低，无需查 PG |
| 简单查询 ("查下运单 SF789") | 不需要历史上下文 |
| 新用户首问，无其他 session | PG 里没有可读的 |
| 同一会话的前几轮 | Redis 已缓存，上下文在滑动窗口内 |

### 16.6 各来源取多少

| 来源 | 取什么 | 取多少 | 条件 |
|------|--------|--------|------|
| **Redis** | 当前会话原文 + skill 结果 | 最近 20 轮 | **每次都读** |
| **PG + Milvus** | 历史相似会话原文 | Top-3 个 Step 的原文 | Query 触发跨会话回忆 |
| **PG (上轮续接)** | 上轮会话最后 N 轮 | 最近 10 轮 | 新会话且无 Redis 缓存 |

### 16.7 完整数据流示例

```
用户: "上次那个延迟单最后怎么处理的？"

Step 3 — Recall:

  ① Redis: 当前会话第1轮，无历史 → 空
  
  ② 触发条件2 (跨会话回忆):
     Query → Embedding → Milvus.search() → 
       [ {session_id:"sess-042", step_id:8, similarity:0.91},
         {session_id:"sess-038", step_id:5, similarity:0.85} ]
  
  ③ 用指针去 PG 拉原文:
     SELECT content FROM conversations
     WHERE session_id='sess-042' AND step_id=8
     → "运单SF123因台风延迟4h,最终方案:通知客户+赔偿运费30%=45元"
  
  ④ 原文注入 LLM Context Window 的 Memory Context 区域:
     [System Prompt] ← Prompt Hub
     [Knowledge]     ← RAG (相关SOP)
     [Memory]        ← ④的原文: "上次延迟单处理结果..."
     [History]       ← 当前对话
     [User Message]  ← "上次那个延迟单最后怎么处理的？"
```

---

### 16.8 Redis 会话缓存 vs 客户端对话历史——为什么客户端有数据还需要 Redis

**客户端与 Redis 存的不是同一份数据，用途也不同。**

**客户端本地有的：** 用户看到的对话气泡——纯文本展示内容。

```
客户端看到的:
  User: "SF123延迟了帮我处理"
  Agent: "检测到延迟4h，预计明天10点送达，建议通知客户并按合同赔偿运费30%。"
```

**Redis 存的是编排引擎内部状态：**

```
Redis 存的 (客户端看不到这些):
  session:sess-042:context
  ├── Step 1: intent={type:delay, confidence:0.92, severity:P2}
  ├── Step 2: knowledge_chunks=5
  ├── Step 3: memory_hits=0
  ├── Step 4: llm_reason_output="TOOL_CALL:track-query(SF123)"
  ├── Step 5: skill_result={status:delayed, eta:"明天10:00", root:"台风"}
  ├── Step 6: llm_reason_output="TOOL_CALL:carrier-sla-lookup"
  ├── Step 7: skill_result={penalty:"运费30%"}
  └── Step 8: llm_reason_output="组装方案:通知客户+赔偿45元"
```

**为什么客户端不能替代 Redis：**

| | 客户端 | Redis |
|---|---|---|
| **有什么** | 只有最终对话气泡 | agent 内部推理链 + skill 调用结果 + 中间状态 |
| **谁用** | 用户看 | 编排引擎推理用 |
| **时效** | 每次用户发来的只有新消息 | 编排引擎随时读/写 |

1. **编排引擎的多步循环在服务端完成**——客户端只看到起点的用户输入和终点的回复，中间步骤全部在编排引擎内部。客户端不知道 Step 5 调了 `track-query`，也不知道它返回了什么数据。

2. **Agent 是多步推理循环**——第二步 LLM 推理需要看到第一步 Skill 的返回结果。如果每次都要客户端回传，客户端根本没有这些中间数据。

3. **K8s 多副本共享状态**——Agent Runtime 有多个 Pod，同一会话的不同请求可能路由到不同 Pod，必须有一个共享的"工作台"存放当前会话的编排状态。Redis 就是那个共享工作台。

4. **客户端只发最新消息**——用户每次只发一条新消息（如 "SF123延迟了"），Agent 编排引擎需要从 Redis 拉取"这条消息之前的所有上下文"来构建 LLM Context Window。

---

### 16.9 Skill 执行结果缓存详细设计

#### 16.9.1 缓存内容

以物流异常处理 Agent 为例，Redis 中存储的 skill 执行结果：

```json
// Redis Hash: session:sess-042:skill_results
{
  "track-query": {
    "called_at_step": 5,
    "request": {"tracking_number": "SF1234567890"},
    "response": {
      "status": "delayed",
      "delayed_duration": "4h15m",
      "current_location": "杭州中转站",
      "estimated_arrival": "2026-05-15T10:00:00",
      "weather_alert": "台风预警",
      "history": [
        {"time": "05-14T08:00", "location": "上海集散中心", "status": "已揽收"},
        {"time": "05-14T14:00", "location": "杭州中转站", "status": "中转"}
      ]
    },
    "duration_ms": 320,
    "success": true
  },
  "abnormal-detection": {
    "called_at_step": 7,
    "request": {"tracking_number": "SF1234567890"},
    "response": {
      "is_abnormal": true,
      "type": "weather_delay",
      "root_cause": "台风艾云尼影响杭州段封路",
      "confidence": 0.95,
      "severity": "P2"
    },
    "duration_ms": 280,
    "success": true
  },
  "carrier-sla-lookup": {
    "called_at_step": 7,
    "request": {"carrier_id": "SF"},
    "response": {
      "carrier": "顺丰速运",
      "promised_eta": 24,
      "actual_elapsed": 28,
      "breach": true,
      "penalty_clause": "延迟>3h赔偿运费30%",
      "compensation_rate": 0.3,
      "max_penalty": 200
    },
    "duration_ms": 450,
    "success": true
  }
}
```

#### 16.9.2 触发时机

在编排引擎的 `execute_skill` 步骤中，skill 调用完成、拿到返回结果后，**立即同步写入 Redis**（在进入下一个 `reason` 步骤之前）。

```python
# orchestrator.py — execute_skill 节点
async def execute_skill(self, state: AgentState) -> AgentState:
    skill_name = state["pending_skill"]
    skill_args = state["pending_skill_args"]
    
    # ① 调用 Skill Registry 执行技能
    result = await self.skill_registry.invoke(skill_name, skill_args)
    
    # ② 立即写入 Redis（同步写，确保下一个 reason 步骤能读到）
    await self.redis.hset(
        f"session:{state.session_id}:skill_results",
        skill_name,
        json.dumps({
            "called_at_step": state["current_step"],
            "request": skill_args,
            "response": result,
            "duration_ms": elapsed_ms,
            "success": True
        })
    )
    
    # ③ 更新 Agent 内部状态
    state["skill_calls"].append({"skill": skill_name, "result": result})
    return state
```

#### 16.9.3 缓存后的用途

| 用途 | 说明 | 时机 |
|------|------|------|
| **注入下一次 LLM 推理** | 下一步 `reason` 时，从 Redis 读取所有已执行的 skill 结果，拼入 Context Window 的 `[Skill Results]` 区域。LLM 看到 "我已经查过运单了，状态是 delayed，根因是台风"，就不会重复调用 `track-query` | 每次 `reason` 步骤前 |
| **防止重复调用** | 编排引擎在 LC 决定调用某个 skill 之前，先检查 Redis——这个 skill 在当前会话已经被调用过了吗？如果是且 TTL 内，直接用缓存结果，不重复调远端 API | 每次 `reason` 步骤输出 TOOL_CALL 后、实际执行前 |
| **最终响应组装** | `respond` 步骤从 Redis 拉全部 skill 结果，用于生成最终的可读回复 | 会话结束时 |
| **审计落盘** | TTL 过期前，异步将 Redis 中的 skill 结果刷入 PG `conversations` 表的对应 step 记录中 | TTL 过期前 |

---

### 16.10 Prompt 与 Agent 的绑定关系

Prompt 通过 Agent DSL 中的 `prompt.ref` 字段与 Agent 绑定：

```yaml
# Agent 定义
spec:
  prompt:
    ref: prompt-logistics-exception-v1   # ← 绑定关系
```

**运行时流程：**

```
编排引擎收到请求: "调用 logistics-exception-handler"

  → 读取 Agent 定义 → 拿到 prompt.ref = "prompt-logistics-exception-v1"
  → POST /prompts/resolve {ref: "prompt-logistics-exception-v1", variables: {...}}
  → Prompt Hub:
      1. 从 PG 查该 ref 的当前生效版本 (status=published)
      2. 检查 base 继承链 → 递归解析多层 Prompt
      3. 填充变量 ({{company_name}} → "XX物流")
      4. 返回完整 System Prompt 纯文本
  → 拼入 Context Window → 调用 LLM
```

**每次推理都重新拉取，不是 Agent 启动时加载到内存。** 改了 Prompt 模板内容，下一次推理立刻生效，无需重启 Agent。

### 17.1 协议选型与背景

A2A (Agent-to-Agent) 是 Google 于 2025 年 4 月发布的开放协议，用于 Agent 间通信。核心解决两个问题：

- **Agent 发现** — Agent A 如何知道 Agent B 存在、能做什么、在哪调用
- **任务委托** — Agent A 如何将任务发送给 Agent B 并获取结果

A2A 与本平台其他协议的定位：

| 协议 | 用途 | 在本平台的位置 |
|------|------|--------------|
| **A2A** | Agent 间任务委托和状态同步 | 多 Agent 协作场景 (Hierarchical/Debate/Mesh) |
| **MCP** | Agent 调用外部 Tool/Skill | Agent → Skill 执行 |
| **内部 gRPC** | 平台内 Agent 间高性能通信 | 同服务内编排引擎 → 编排引擎 |
| **REST** | 外部系统集成 | Java 后端 → Agent 服务 |

### 17.2 开源现状与选型

| 组件 | 成熟度 | 结论 |
|------|--------|------|
| Google A2A 协议规范 | ✅ 2025.4 发布，稳定 | 采用标准协议 |
| Google 官方 SDK (Python/Java/JS) | ✅ 可用 | 采用官方 SDK 实现通信层 |
| 开源 A2A Registry | ❌ 社区实验项目，stars<100 | **自研** |

结论：**A2A 通信层用 Google 官方 SDK，Registry 自研。** 自研成本不高——核心仅 ~300 行代码 + 一张 PG 表。

### 17.3 Agent Card 标准

A2A 协议的核心是 Agent Card——每个 Agent 的标准自描述文件，暴露在 `GET /.well-known/agent.json`：

```json
{
  "name": "logistics-exception-handler",
  "description": "物流运输异常处理 Agent。识别延迟、破损、丢件、地址错误、海关滞留五类异常，按 P1/P2/P3 分级处理。",
  "url": "https://agent-service.ai-platform/agents/exception",
  "provider": {
    "organization": "AI 平台部",
    "url": "https://ai-platform.example.com"
  },
  "capabilities": {
    "streaming": true,
    "pushNotifications": true,
    "stateTransitionHistory": true
  },
  "skills": [
    {
      "id": "track-query",
      "name": "运单状态查询",
      "description": "【何时调用】需要查询运单实时状态时；【输出】status, location, eta, history",
      "tags": ["logistics", "tracking"]
    },
    {
      "id": "abnormal-detection",
      "name": "异常检测",
      "description": "【何时调用】用户描述了运单异常情况时；【输出】is_abnormal, type, severity, root_cause",
      "tags": ["logistics", "exception", "delay"]
    },
    {
      "id": "carrier-sla-lookup",
      "name": "承运商 SLA 查询",
      "description": "【何时调用】需要查询承运商合同条款和赔偿标准时；【输出】promised_eta, penalty_clause, compensation_rate",
      "tags": ["logistics", "sla", "carrier"]
    }
  ],
  "defaultInputModes": ["text"],
  "defaultOutputModes": ["text"],
  "version": "1.0.0",
  "status": "active"
}
```

### 17.4 Agent 自动发现流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent 自动发现三步                             │
│                                                                 │
│  ① 启动注册                                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ 每个 Agent 启动时:                                         │   │
│  │   1. 读取自己的 agent.json (Agent Card)                    │   │
│  │   2. POST /a2a/agents/register → A2A Registry             │   │
│  │   3. 启动后台心跳，每 30s: PUT /heartbeat                  │   │
│  │   超时 90s 未心跳 → Registry 自动标记 offline              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ② 技能发现                                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Supervisor Agent 需要委托子任务时:                          │   │
│  │   GET /a2a/agents?skill=delay_detection&status=active     │   │
│  │   → Registry 返回匹配的 Agent 列表 (按技能描述+标签匹配)     │   │
│  │                                                          │   │
│  │   匹配算法:                                                │   │
│  │   · 技能 ID 精确匹配 (最高权重)                             │   │
│  │   · 技能 description 语义匹配 (中等权重)                    │   │
│  │   · 标签 tags 交集 (最低权重)                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                         │                                        │
│                         ▼                                        │
│  ③ 任务委托                                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Supervisor 选定目标 Agent → 通过 Higress Gateway 路由:      │   │
│  │   POST /a2a/tasks (send)                                  │   │
│  │   {                                                       │   │
│  │     "id": "task-001",                                     │   │
│  │     "sessionId": "sess-042",                              │   │
│  │     "message": {"role": "user",                           │   │
│  │       "parts": [{"text": "分析运单SF123延迟原因"}]}         │   │
│  │   }                                                       │   │
│  │   → SSE 流式返回中间状态 → 最终返回 completed/failed        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 17.5 A2A Registry 自研实现

#### 17.5.1 数据模型

```sql
-- A2A Registry 核心表 (复用 ai_platform PG)
CREATE TABLE a2a_agents (
    id              SERIAL PRIMARY KEY,
    name            TEXT UNIQUE NOT NULL,       -- Agent 唯一名称
    url             TEXT NOT NULL,              -- 调用地址
    description     TEXT,                       -- 功能描述
    organization    TEXT,                       -- 所属组织
    capabilities    JSONB DEFAULT '{}',         -- {streaming, push, stateHistory}
    skills          JSONB DEFAULT '[]',         -- [{id, name, description, tags}]
    tags            TEXT[] DEFAULT '{}',        -- 全局标签，用于粗筛
    version         TEXT,
    status          TEXT DEFAULT 'active',      -- active | offline | error
    last_heartbeat  TIMESTAMPTZ DEFAULT NOW(),
    registered_at   TIMESTAMPTZ DEFAULT NOW(),
    metadata        JSONB DEFAULT '{}'          -- 扩展字段
);

-- 索引
CREATE INDEX idx_a2a_agents_status ON a2a_agents(status);
CREATE INDEX idx_a2a_agents_tags ON a2a_agents USING GIN(tags);
CREATE INDEX idx_a2a_agents_skills ON a2a_agents USING GIN(skills);
```

#### 17.5.2 API 设计

```
POST   /a2a/agents/register      # Agent 注册
PUT    /a2a/agents/:name/heartbeat  # 心跳续约
DELETE /a2a/agents/:name          # Agent 下线/注销
GET    /a2a/agents                # 查询/发现 (支持 skill/capability/tags/status 过滤)
GET    /a2a/agents/:name          # 获取单个 Agent Card
```

#### 17.5.3 核心实现

```python
# a2a-registry/registry.py
import asyncio
from datetime import datetime, timezone, timedelta
from fastapi import FastAPI, HTTPException, Query

app = FastAPI(title="A2A Registry Service")

class A2ARegistry:
    """Agent 注册中心 — 核心仅需 ~300 行"""
    
    def __init__(self, db):
        self.db = db
        # 启动后台清理任务
        asyncio.create_task(self._cleanup_offline_agents())
    
    async def register(self, agent_card: dict) -> dict:
        """Agent 启动注册"""
        existing = await self.db.fetchrow(
            "SELECT id FROM a2a_agents WHERE name = $1",
            agent_card["name"]
        )
        if existing:
            # 重连场景：更新状态和心跳
            await self.db.execute("""
                UPDATE a2a_agents 
                SET status = 'active', 
                    url = $2,
                    skills = $3,
                    tags = $4,
                    last_heartbeat = NOW()
                WHERE name = $1
            """, agent_card["name"], agent_card["url"],
                agent_card.get("skills", []), agent_card.get("tags", []))
        else:
            await self.db.execute("""
                INSERT INTO a2a_agents (name, url, description, organization, 
                    capabilities, skills, tags, version)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            """, agent_card["name"], agent_card["url"],
                agent_card.get("description"),
                agent_card.get("provider", {}).get("organization"),
                agent_card.get("capabilities", {}),
                agent_card.get("skills", []),
                agent_card.get("tags", []),
                agent_card.get("version"))
        
        return {"status": "registered", "name": agent_card["name"]}
    
    async def heartbeat(self, agent_name: str):
        """每 30s 心跳续约"""
        result = await self.db.execute("""
            UPDATE a2a_agents 
            SET last_heartbeat = NOW(), status = 'active'
            WHERE name = $1
        """, agent_name)
        if result == "UPDATE 0":
            raise HTTPException(404, "Agent not found")
        return {"status": "ok"}
    
    async def search(
        self, 
        skill: str = None,
        capability: str = None,
        tags: list[str] = None,
        status: str = "active"
    ) -> list[dict]:
        """Agent 发现 — Supervisor 用这个找子 Agent"""
        
        query = "SELECT * FROM a2a_agents WHERE status = $1"
        params = [status]
        param_idx = 2
        
        if skill:
            # 技能匹配: 先精确匹配 ID，再语义匹配 description
            query += f" AND ("
            query += f"  skills::jsonb @> '[{{\"id\": \"{skill}\"}}]'::jsonb"
            query += f"  OR skills::text ILIKE $%d" % param_idx
            query += f" )"
            params.append(f"%{skill}%")
            param_idx += 1
        
        if tags:
            # 标签交集
            query += f" AND tags && $%d::text[]" % param_idx
            params.append(tags)
            param_idx += 1
        
        query += " ORDER BY last_heartbeat DESC LIMIT 20"
        
        rows = await self.db.fetch(query, *params)
        return [
            {
                "name": r["name"], "url": r["url"],
                "description": r["description"],
                "skills": r["skills"], "tags": r["tags"],
                "status": r["status"]
            }
            for r in rows
        ]
    
    async def deregister(self, agent_name: str):
        """Agent 下线"""
        await self.db.execute("""
            UPDATE a2a_agents SET status = 'offline' WHERE name = $1
        """, agent_name)
        return {"status": "deregistered"}
    
    async def _cleanup_offline_agents(self):
        """后台任务: 超过 90s 未心跳 → 标记 offline"""
        while True:
            await asyncio.sleep(30)
            threshold = datetime.now(timezone.utc) - timedelta(seconds=90)
            await self.db.execute("""
                UPDATE a2a_agents 
                SET status = 'offline'
                WHERE status = 'active' 
                  AND last_heartbeat < $1
            """, threshold)


# FastAPI 路由
@app.post("/a2a/agents/register")
async def register(agent_card: dict):
    return await registry.register(agent_card)

@app.put("/a2a/agents/{name}/heartbeat")
async def heartbeat(name: str):
    return await registry.heartbeat(name)

@app.get("/a2a/agents")
async def search(
    skill: str = Query(None),
    tags: list[str] = Query(None),
    status: str = "active"
):
    return await registry.search(skill=skill, tags=tags, status=status)

@app.delete("/a2a/agents/{name}")
async def deregister(name: str):
    return await registry.deregister(name)
```

### 17.6 Supervisor Agent 如何使用 A2A 发现 + 委托

```python
# orchestrator/supervisor.py
from google.a2a import A2AClient  # Google 官方 SDK
from google.a2a.types import Task, Message, Part

class SupervisorAgent:
    
    def __init__(self, registry_url: str):
        self.registry = A2ARegistryClient(registry_url)
    
    async def delegate_complex_task(self, task: dict) -> dict:
        """处理复合异常 (如延迟+破损)"""
        
        # Step 1: 从 Registry 发现可用的 Specialist Agent
        agents = await self.registry.search(
            skill=task["required_skill"],  # "delay_detection"
            tags=["logistics"]
        )
        
        if not agents:
            # 没找到 → 降级: Supervisor 自己处理
            return await self._handle_locally(task)
        
        # Step 2: 选择最优 Agent
        target = self._select_best_match(task, agents)
        
        # Step 3: A2A 任务委托
        a2a_client = A2AClient(agent_url=target["url"])
        
        task_result = await a2a_client.send_task(
            task=Task(
                id=f"subtask-{uuid4()}",
                session_id=task["parent_session_id"],
                message=Message(
                    role="user",
                    parts=[Part(text=task["sub_query"])]
                )
            )
        )
        
        # Step 4: SSE 流式等待完成
        async for event in a2a_client.get_task_updates(task_result.id):
            if event.status == "completed":
                return event.artifacts[0].parts[0].text
        
        return {"status": "failed", "reason": "timeout"}
    
    def _select_best_match(self, task: dict, agents: list[dict]) -> dict:
        """技能匹配 + 负载均衡选最优"""
        scored = []
        for agent in agents:
            # 技能关键词匹配
            skill_score = sum(
                3 if s["id"] == task.get("required_skill") else
                1 if task.get("query", "") in s.get("description", "")
                else 0
                for s in agent["skills"]
            )
            scored.append((agent, skill_score))
        scored.sort(key=lambda x: x[1], reverse=True)
        return scored[0][0]
```

### 17.7 A2A 在本平台中的位置

```
┌──────────────────────────────────────────────────────────────────┐
│                     A2A 在平台中的完整位置                          │
│                                                                  │
│  跨 Agent 通信层 (A2A 协议)                                        │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Supervisor Agent ──A2A──► Specialist Agent A              │  │
│  │         │                         │                        │  │
│  │         ├──A2A──► Specialist Agent B                       │  │
│  │         │                         │                        │  │
│  │         └──A2A──► Specialist Agent C                       │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              │                                    │
│        Higress Gateway (流量路由 + 灰度 + 安全)                    │
│                              │                                    │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  A2A Registry Service (自研，~300行 + 1张PG表)              │    │
│  │  · Agent Card 注册/心跳/下线                               │    │
│  │  · 技能匹配发现                                             │    │
│  │  · 与 Skill Registry 共用 PG 实例                           │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                  │
│  Agent 内部编排层 (LangGraph StateGraph)                           │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  LangGraph 进程内 StateGraph:                              │    │
│  │  understand → retrieve → recall → reason ⇄ skill → respond│    │
│  │  (不经过 A2A 协议，不经过网络)                               │    │
│  └──────────────────────────────────────────────────────────┘    │
└──────────────────────────────────────────────────────────────────┘
```

### 17.8 部署规格

| 指标 | 值 |
|------|-----|
| 服务名称 | `a2a-registry` |
| 部署方式 | K8s Deployment，2 副本 |
| 数据库 | 复用 ai_platform PG 的 `a2a_agents` 表 |
| 资源需求 | 0.5 vCPU, 256MB RAM |
| 心跳间隔 | 30s |
| 超时下线 | 90s (3 次心跳未响应) |
| 外部依赖 | 无（不引入新中间件） |

---

---

## 18. 技能市场：服务边界与发布生效机制

### 18.1 定位——技能市场不是独立服务

**技能市场 = Skill Registry（后端）+ Admin UI（前端展示）。** 不需要新建服务，复用已有组件。

| 组件 | 角色 | 部署方式 |
|------|------|---------|
| **Skill Registry** | 技能市场后端：技能定义存储、注册/注销 API、版本管理、执行路由 | K8s Deployment（2 副本），第 10 章 Phase 3 部署 |
| **Admin UI** | 技能市场前端：技能浏览/搜索、上架审核、订阅/计费管理、技能详情展示 | 平台管理后台的内嵌模块 |
| **PostgreSQL** | 技能定义持久化存储（`skills` 表），与 Skill Registry 共用 PG 实例 | 已有基础设施 |

### 18.2 技能数据模型

```sql
-- 技能定义表 (在 ai_platform PG 中)
CREATE TABLE skills (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,                 -- 技能唯一名称 (如 track-query)
    version         TEXT NOT NULL DEFAULT '1.0.0', -- 语义化版本
    type            TEXT NOT NULL,                 -- mcp_server | api | wasm | code
    endpoint        TEXT NOT NULL,                 -- mcp://tracking/query 或 http://xxx
    description     TEXT NOT NULL,                 -- 结构化的调用描述 (LLM 据此判断何时调用)
    parameters      JSONB NOT NULL DEFAULT '[]',   -- [{name, type, required, description}]
    output_schema   JSONB,                         -- 输出 JSON Schema
    industry        TEXT,                          -- logistics | finance | common
    provider        TEXT,                          -- platform-official | isv | community
    status          TEXT NOT NULL DEFAULT 'draft', -- draft | review | published | deprecated
    reviewed_by     TEXT,                          -- 审核人
    reviewed_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 技能与 Agent 的绑定关系
CREATE TABLE agent_skills (
    agent_name      TEXT REFERENCES agents(name),
    skill_name      TEXT REFERENCES skills(name),
    required        BOOLEAN DEFAULT false,  -- 是否必需
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (agent_name, skill_name)
);
```

### 18.3 技能发布生效流程

```
┌──────────────────────────────────────────────────────────────┐
│                 技能发布生效流程                                │
│                                                              │
│  Step 1: 开发 & 注册                                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 开发者 → Admin UI / CLI:                                │  │
│  │   $ ai skill create track-query                        │  │
│  │   → 填写 Skill DSL                                     │  │
│  │   → POST /skills/register → Skill Registry             │  │
│  │   → PG INSERT: status = 'draft'                        │  │
│  │   → 此时只有创建者可见，Agent 看不到                       │  │
│  └────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  Step 2: 测试 & 审核                                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 开发者 → 技能沙箱测试 (Skill Sandbox)                    │  │
│  │   调用技能端点 → 验证输入/输出符合 Schema                  │  │
│  │   测试通过 → 提交审核: status = 'review'                 │  │
│  │                                                       │  │
│  │ 平台管理员 → 审核:                                       │  │
│  │   代码安全扫描 → 权限审查 → 数据流向检查 → 通过           │  │
│  │   → status = 'published'                               │  │
│  └────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  Step 3: 即时生效 (无需重启)                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 技能状态变为 published → 实时生效                         │  │
│  │                                                       │  │
│  │ 生效路径:                                               │  │
│  │   PG 写入 (published)                                   │  │
│  │     → Agent 每次推理时实时查询 Skill Registry:           │  │
│  │         GET /skills?agent=logistics-exception-handler   │  │
│  │     → Registry 返回该 Agent 绑定的、status=published     │  │
│  │       的技能的 description 列表                           │  │
│  │     → 编排引擎将 description 列表注入 LLM Context Window │  │
│  │       的 Tool Definition 区域                            │  │
│  │     → LLM 看到的就是当前已发布的最新版本技能列表           │  │
│  │                                                       │  │
│  │  关键: 技能 description 不是 Agent 启动时缓存到内存的     │  │
│  │        静态配置, 而是每次推理时实时查询 Registry 的       │  │
│  └────────────────────────────────────────────────────────┘  │
│                         │                                     │
│                         ▼                                     │
│  Step 4: 版本迭代 (新版本发布不影响旧 Agent)                    │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 技能版本管理 (semver):                                   │  │
│  │                                                       │  │
│  │   track-query v1.0.0 → v2.0.0 (Breaking Change)       │  │
│  │                                                       │  │
│  │   发布 v2.0.0 时:                                       │  │
│  │     · 新 Agent 创建时默认绑定最新版本                     │  │
│  │     · 已有 Agent 继续使用绑定的版本 (v1.0.0)，不受影响    │  │
│  │     · 开发者可手动升级 Agent 的技能绑定:                  │  │
│  │         PUT /agents/exception-handler/skills/track-query│  │
│  │         {version: "2.0.0"}                             │  │
│  │                                                       │  │
│  │  补丁版本 (v1.0.0 → v1.0.1):                            │  │
│  │     · 仅修改 description (措辞优化) 或 endpoint (URL变更)│  │
│  │     · 同一 Major.Minor 下自动生效，所有绑定该技能的 Agent  │  │
│  │       下次推理时拿到最新 Patch 版本                        │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### 18.4 技能生效时机——Agent 什么时候拉取技能列表

| 时机 | 频率 | 查询内容 | 说明 |
|------|------|---------|------|
| **Agent 定义引用** | Agent 创建/更新时 | Skill Registry 校验技能是否存在、版本是否可用 | 引用不存在的技能 → 创建失败 |
| **Agent 每次推理** | 每次 `reason` 步骤前 | `GET /skills?agent={name}`→ 返回该 Agent 绑定的、已发布的、当前 Patch 版本的技能 description 列表 | 实时查询，非内存缓存，修改 description 瞬间生效 |
| **Admin UI 浏览** | 开发者浏览技能市场时 | `GET /skills?status=published&industry=logistics` | 与 Agent 运行时共用同一 Registry |

### 18.5 技能 description 热更新的特殊价值

技能 description 是 LLM 判断"何时调用这个技能"的唯一依据。修改 description 是提升 Agent 准确率最快的手段（不需要重新训练，不需要改代码）：

```
修改前:
  description: "查询运单"

修改后:
  description: |
    【功能】查询运单实时状态和轨迹
    【何时调用】用户提供了运单号、或提到了查询运单/快递/物流状态时
    【何时不调用】仅查询承运商信息(非具体运单)、查询运费/价格时
    【依赖】需要 tracking_number 参数
    【输出】status, location, eta, history

修改后下一次 Agent 推理 → LLM 看到新的 description → 调用准确率立即提升。

不需要:
  · 重启 Agent 服务 ❌
  · 重新部署 ❌
  · 修改 Agent DSL ❌
  · 等待生效 ❌
```

### 18.6 与 A2A Registry 的边界

| | Skill Registry | A2A Registry |
|---|---|---|
| **注册什么** | 单个技能（工具/API） | 整个 Agent |
| **谁调用** | Agent 编排引擎（每次推理时） | Supervisor Agent（需要委托子任务时） |
| **发布粒度** | 技能级别 (Skill) | Agent 级别 (Agent Card) |
| **生效方式** | 每次推理实时查询 | Agent 启动注册 + 心跳 + 超时下线 |
| **存储** | PG `skills` 表 | PG `a2a_agents` 表（共用 PG 实例） |
| **独立服务** | ✅ 是（skill-registry Deployment） | ✅ 是（a2a-registry Deployment） |

### 18.7 Skill 术语澄清——本平台 Skill 与 AI 编码助手 Skill 的区别

本平台中的 "Skill" 与 Claude Code 等 AI 编码助手中的 "Skill" 是同名异义，本质不同：

| | Claude Code "Skill" | AI Agent 平台 "Skill" |
|---|---|---|
| **本质** | 指令注入（Prompt Template） | 外部 API 调用（Tool） |
| **作用** | 告诉 AI **怎么想** | 让 AI **怎么做** |
| **加载方式** | 注入 System Prompt，影响推理行为 | 通过 MCP / REST API / gRPC 远程调用 |
| **执行结果** | 改变 AI 的推理策略和行为规范 | 获取外部数据或执行外部动作 |
| **示例** | `harness-brainstorming` → "遵循9步设计流程" | `track-query` → 调用 TMS API 查运单 |
| **在本平台的对应** | **Prompt Template**（存在 Prompt Hub） | **Skill**（存在 Skill Registry） |

具体到物流异常处理 Agent：

- **Prompt Template 负责 "怎么想"**： "你是物流异常处理专家。识别五类异常并按 P1/P2/P3 分级..."

- **Skill 负责 "怎么做"**： `track-query` 调 TMS 查运单、`customer-notify` 调通知服务发短信、`carrier-sla-lookup` 调查承运商合同

本方案沿用了业界通用术语（Manhattan Agent Foundry、Google A2A 协议均使用 "Skill" 指代 Agent 可调用的工具能力），但应注意与 AI 编码助手生态的 Skill 概念区分。

---

*文档结束。*
