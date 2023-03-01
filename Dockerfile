FROM alpine

# 设置镜像源
ENV PIP_INDEX_URL=https://mirrors.aliyun.com/pypi/simple/
ENV PIP_TRUSTED_HOST=mirrors.aliyun.com
ENV NPM_CONFIG_REGISTRY=https://registry.npmmirror.com
RUN sed -i 's,dl-cdn.alpinelinux.org,mirrors.aliyun.com,g' /etc/apk/repositories

ENV LANG="C.UTF-8" \
    TZ="Asia/Shanghai" \
    NASTOOL_CONFIG="/config/config.yaml" \
    NASTOOL_AUTO_UPDATE=true \
    NASTOOL_CN_UPDATE=true \
    NASTOOL_VERSION=master \
    PS1="\u@\h:\w \$ " \
    REPO_URL="https://github.com/NAStool/nas-tools.git" \
    PYPI_MIRROR="https://pypi.tuna.tsinghua.edu.cn/simple" \
    ALPINE_MIRROR="mirrors.ustc.edu.cn" \
    PUID=0 \
    PGID=0 \
    UMASK=000 \
    WORKDIR="/nas-tools"
WORKDIR ${WORKDIR}

RUN apk update
RUN apk add --no-cache libffi-dev


ADD package_list.txt .
RUN apk add --no-cache $(cat package_list.txt)

RUN ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime \
    && echo "${TZ}" > /etc/timezone \
    && ln -sf /usr/bin/python3 /usr/bin/python

RUN curl https://rclone.org/install.sh | bash
RUN curl https://dl.min.io/client/mc/release/linux-amd64/mc --create-dirs -o /usr/bin/mc \
    && chmod +x /usr/bin/mc
RUN pip install --upgrade pip setuptools wheel
RUN pip install cython

ADD requirements.txt .
RUN pip install -r requirements.txt
RUN npm install pm2 -g

RUN python_ver=$(python3 -V | awk '{print $2}') \
    && echo "${WORKDIR}/" > /usr/lib/python${python_ver%.*}/site-packages/nas-tools.pth \
    && echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf \
    && echo 'fs.inotify.max_user_instances=524288' >> /etc/sysctl.conf \
    && git config --global pull.ff only \
    && git config --global --add safe.directory ${WORKDIR}

ADD . .
RUN chmod +x ${WORKDIR}/docker/entrypoint.sh
RUN git remote set-url origin ${REPO_URL}

EXPOSE 3000
VOLUME ["/config"]
ENTRYPOINT ["/nas-tools/docker/entrypoint.sh"]