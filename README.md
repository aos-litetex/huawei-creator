# Huawei Creator

## Usage

Generate ARM64 AB (Huawei device) from ARM64 AB and include patchs and optimisations (target image name is s-ab.img):

    sudo ./run-huawei-ab.sh systemAB.img "LeaOS" "ANE-LX1"

### Docker

```bash
docker build -t huawei-creator .
# --privileged  is required for mount
docker run --rm -it -v "%cd%":/data/huawei-creator --privileged  huawei-creator

./run-huawei-emui9-ab-a13.sh system.img "LeaOS" "ANE-LX1"
```
