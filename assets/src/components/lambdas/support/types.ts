export type BeforeUploadFileType = File | Blob | boolean | string;

export interface UploadProgressEvent<T> extends ProgressEvent {
  percent: number;
}

export type UploadRequestMethod =
  | 'POST'
  | 'PUT'
  | 'PATCH'
  | 'post'
  | 'put'
  | 'patch';

export type UploadRequestHeader = Record<string, string>;

export interface UploadRequestError extends Error {
  status?: number;
  method?: UploadRequestMethod;
  url?: string;
}

export interface UploadRequestOption<T = any> {
  onProgress?: (event: ProgressEvent<EventTarget>) => void;
  onError?: (event: UploadRequestError | ProgressEvent, body?: T) => void;
  onSuccess?: (body: T, xhr?: XMLHttpRequest) => void;
  data?: Record<string, any>;
  filename?: string;
  file: Exclude<BeforeUploadFileType, File | boolean>;
  withCredentials?: boolean;
  action: string;
  headers?: UploadRequestHeader;
  method: UploadRequestMethod;
}
