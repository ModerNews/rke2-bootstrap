# Cloud-init

Cloud-init files can be overlayed on top of each other using MIME multipart format.

In this directory there are provided 3 partial cloud-init files:
- base.yaml
- master-overlay.yaml
- worker-overlay.yaml

You can combine them into a mime multipart file using provided `make-mime.py` script, i.e.:

```sh
python3 make-mime.py base.yaml master-overlay.yaml user-data-master.yaml
```

You could also potentially use `cloud-init devel make-mime` command, but due to problems with the package we provide our own minimal implementation.
