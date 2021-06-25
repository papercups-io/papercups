import {noop} from '../../../utils';
import type {UploadRequestOption, UploadRequestError} from './types';

/**
 * Taken from https://github.com/react-component/upload/blob/master/src/request.ts
 */

function getError(option: UploadRequestOption, xhr: XMLHttpRequest) {
  const msg = `cannot ${option.method} ${option.action} ${xhr.status}'`;
  const err = new Error(msg) as UploadRequestError;

  err.status = xhr.status;
  err.method = option.method;
  err.url = option.action;

  return err;
}

function getBody(xhr: XMLHttpRequest) {
  const text = xhr.responseText || xhr.response;
  if (!text) {
    return text;
  }

  try {
    return JSON.parse(text);
  } catch (e) {
    return text;
  }
}

export default function upload(option: UploadRequestOption) {
  // eslint-disable-next-line no-undef
  const xhr = new XMLHttpRequest();
  const {
    data = {},
    filename = '',
    file,
    onProgress = noop,
    onError = noop,
    onSuccess = noop,
  } = option;

  if (onProgress && xhr.upload) {
    xhr.upload.onprogress = function progress(e: ProgressEvent<EventTarget>) {
      onProgress(e);
    };
  }

  // eslint-disable-next-line no-undef
  const formData = new FormData();

  if (data) {
    Object.keys(data).forEach((key) => {
      const value = data[key];
      // support key-value array data
      if (Array.isArray(value)) {
        value.forEach((item) => {
          // { list: [ 11, 22 ] }
          // formData.append('list[]', 11);
          formData.append(`${key}[]`, item);
        });
        return;
      }

      formData.append(key, data[key]);
    });
  }

  // eslint-disable-next-line no-undef
  if (file instanceof Blob) {
    formData.append(filename, file, (file as any).name);
  } else {
    formData.append(filename, file);
  }

  xhr.onerror = function error(e) {
    onError(e);
  };

  xhr.onload = function onload() {
    // allow success when 2xx status
    // see https://github.com/react-component/upload/issues/34
    if (xhr.status < 200 || xhr.status >= 300) {
      return onError(getError(option, xhr), getBody(xhr));
    }

    return onSuccess(getBody(xhr), xhr);
  };

  xhr.open(option.method, option.action, true);

  // Has to be after `.open()`. See https://github.com/enyo/dropzone/issues/179
  if (option.withCredentials && 'withCredentials' in xhr) {
    xhr.withCredentials = true;
  }

  const headers = option.headers || {};

  // when set headers['X-Requested-With'] = null , can close default XHR header
  // see https://github.com/react-component/upload/issues/33
  if (headers['X-Requested-With'] !== null) {
    xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
  }

  Object.keys(headers).forEach((h) => {
    if (headers[h] !== null) {
      xhr.setRequestHeader(h, headers[h]);
    }
  });

  xhr.send(formData);

  return {
    abort() {
      xhr.abort();
    },
  };
}
