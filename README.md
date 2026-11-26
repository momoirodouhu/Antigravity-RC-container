# Antigravity-RC-container

Kubernetes 上で **Antigravity CLI (`agy`) Remote Control** をヘッドレス・非 root（`UID/GID 1000`）で常駐稼働させるためのコンテナイメージおよびマニフェストです。

## 特徴

- **非 root 実行 & PVC 永続化**: `dev` ユーザー（`UID/GID 1000`）で実行し、`/home/dev` のみを PVC で永続化します。
- **ユーザー空間パッケージ管理**: `mise` / `uv` を同梱しており、権限昇格なしで CLI ツールや言語ランタイムを `/home/dev/.local` 配下へ動的に追加・永続化できます。
- **環境仕様の自動注入**: イメージ内の `/opt/antigravity/ENV_PROFILE.md` を起動時に `~/.gemini/GEMINI.md` へシンボリックリンクし、エージェントに環境制約・ツール一覧を自動認識させます。
- **Daemon 監視ループ**: `entrypoint.sh` が `agy remote-control start` を起動して `status` を監視します。初回未認証で起動に失敗した場合もコンテナを維持するため、`kubectl exec` でのログイン作業が可能です。

## ファイル構成

- `Containerfile`: `debian:bookworm-slim` (`linux/amd64`) ベースのコンテナイメージ定義
- `ENV_PROFILE.md`: エージェント向けの環境仕様ドキュメント（英語）
- `entrypoint.sh`: ディレクトリ初期化・ルールリンク・`agy remote-control` 起動＆監視スクリプト
- `k8s/statefulset.yaml`: Kubernetes StatefulSet（PVC 10Gi マウント）雛形
- `.github/workflows/build.yml`: ビルド・非 root スモークテスト・GHCR (`ghcr.io/momoirodouhu/antigravity-rc-container`) への Push ワークフロー

## 同梱ツール

- **本体 / 開発**: `agy`, `coder`, `git`, `gh`, `curl`, `wget`, `jq`, `yq`, `ripgrep` (`rg`), `fd`, `openssh-client`
- **ランタイム / パッケージ管理**: `python3` (`pip`, `venv`), `node` (22 LTS, `npm`), `mise`, `uv`
- **Kubernetes**: `kubectl`, `kubelogin` (OIDC), `helm`, `kustomize`
- **調査系**: `procps` (`ps`/`top`), `iproute2` (`ip`/`ss`), `iputils-ping`, `dnsutils` (`dig`), `mtr`, `netcat-openbsd`, `lsof`, `strace`, `socat`

## クイックスタート（Kubernetes）

1. **StatefulSet のデプロイ**

   ```bash
   kubectl apply -f k8s/statefulset.yaml
   ```

2. **初回 OAuth ログイン**

   初回起動時は未認証のため、コンテナはログイン待機状態で稼働します。Pod に入って認証を行ってください。

   ```bash
   kubectl exec -it antigravity-rc-0 -- agy
   ```

3. **Pod の再起動と稼働確認**

   認証完了後、Pod を再作成すると永続化された認証情報を使って自動で Remote Control デーモンが起動します。

   ```bash
   kubectl delete pod antigravity-rc-0
   kubectl exec antigravity-rc-0 -- agy remote-control status
   ```

## 補足

- `~/.gemini/GEMINI.md` はイメージ管理の読み取り専用シンボリックリンクです。プロジェクト固有やユーザー独自の指示はワークスペース配下の `GEMINI.md` 等に配置してください。
