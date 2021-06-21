import JSZip from 'jszip';
import JSZipUtils from 'jszip-utils';
import {
  DEFAULT_LAMBDA_PREAMBLE,
  WEBHOOK_HANDLER_SOURCE,
} from '../../developers/RunKit';

const DEMO_SOURCE_CODE = WEBHOOK_HANDLER_SOURCE.concat(DEFAULT_LAMBDA_PREAMBLE);

export const zipSingleFile = (code = DEMO_SOURCE_CODE) => {
  const zip = new JSZip();

  zip.file('index.js', code);

  return zip.generateAsync({type: 'blob'});
};

export const zipWithDependencies = async (code = DEMO_SOURCE_CODE) => {
  const file = `${window.location.origin}/deps`;
  const zip = new JSZip();

  return JSZipUtils.getBinaryContent(file)
    .then((data: any) => {
      return zip.loadAsync(data);
    })
    .then(() => {
      // TODO: don't hardcode value here?
      zip.file('index.js', code.concat(DEFAULT_LAMBDA_PREAMBLE));

      return zip.generateAsync({type: 'blob'});
    });
};
