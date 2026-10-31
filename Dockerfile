FROM nginx:alpine
LABEL maintainer="USEA Group 1 (SARAN Chamroeun, SOM Liheng, NGY LYTENG)"
COPY index.html /usr/share/nginx/html/index.html
HEALTHCHECK --interval=15s --timeout=3s --retries=3 CMD wget -q -O /dev/null http://localhost/ || exit 1
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
