import upload from './upload';
import {UploadRequestOption} from './types';
import * as API from '../../../api';
import {noop} from '../../../utils';
import {Lambda} from '../../../types';

export default function deploy(
  lambdaId: string,
  file: File | Blob,
  options: Partial<UploadRequestOption> = {}
): Promise<Lambda> {
  const {
    data = {},
    withCredentials,
    onProgress = noop,
    onSuccess = noop,
    onError = noop,
  } = options;

  return new Promise((resolve, reject) => {
    const token = API.getAccessToken();

    if (!token) {
      return reject(new Error('Invalid token!'));
    }

    upload({
      action: `/api/lambdas/${lambdaId}/deploy`,
      filename: 'file',
      data,
      file,
      headers: {
        Authorization: token,
      },
      withCredentials,
      method: 'post',
      onProgress: (e) => onProgress(e),
      onSuccess: ({data}) => {
        onSuccess(data);
        resolve(data);
      },
      onError: (err) => {
        onError(err);
        reject(err);
      },
    });
  });
}
