Step 1 -3 is for On Demand Service Broker Only
1. Download On Demand Service SDK from: https://network.pivotal.io/products/on-demand-services-sdk/
2. Download On Demand Service Adatper from: https://github.com/df010/ondemand-service-adapter-release, and create a release
3. Place downloaded SDK, and created adatper bosh release into folder releases/
4. In the bosh release folder, where you want to create a service tile, add a manifests/template.yml. For example, refer to https://github.com/df010/postgres-standby-boshrelease
5. run tile.sh BOSH_RELEASE_FOLDER to generate the service tile, result can be found in build/*.pivotal
