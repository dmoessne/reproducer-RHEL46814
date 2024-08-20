# reproducer-RHEL46814
Things needed to reproduce the SR-IOV issue
- Bare metal system with Intel E810:
  - OCP 4.16.0+
  - At least one VLAN the test pod(s) can be attachted to 
  - RH SR-IOV Operator installed 
- Configuration as follows:
  - SR-IOV Operator Config 
   ```
    oc get -o yaml sriovoperatorconfig -n openshift-sriov-network-operator
    apiVersion: v1
    items:
    - apiVersion: sriovnetwork.openshift.io/v1
      kind: SriovOperatorConfig
      metadata:
      name: default
      namespace: openshift-sriov-network-operator
    spec:
      disableDrain: true
      enableInjector: false
      enableOperatorWebhook: false
      logLevel: 2
    kind: List
    metadata:
      resourceVersion: ""
   ```
 - **MIND** all the following settings like interface name, VLAN IDs, IPs depend on your setup and will most likely need to be changed
   - create test namespace, sa and add scc to user, e.g.:
     - `oc new-project sriov-test`
     - `oc create sa priviledged-sa`
     - `oc adm policy add-scc-to-user privileged -z priviledged-sa`
   - create `SriovNetworkNodePolicy`, e.g. [01-SriovNetworkNodePolicy/sriov-config-netdevice-enp5s0f1.yaml]
   - create `NetworkAttachmentDefinition`, e.g.
   - create `StatefulSet` running a pod with a VLAN set up inside the pod, e.g
   - run a simple ping test, e.g. `for I in {0..9}; do echo -n po-vlan10${I}-0 : ; oc rsh po-vlan10${I}-0 ping -c3 192.168.10${I}.31 |grep transmi;done`
   - to run this in a loop, check out
- in case you do want or need to build a custom image for testing, see https://github.com/dmoessne/rhcos-layering
