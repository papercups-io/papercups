import {RcFile} from 'rc-upload/lib/interface';
import RcUpload from 'rc-upload';
import {Button, Popover} from '../common';
import {PaperClipOutlined} from '../icons';
import React from 'react';

type Props = {};
type State = {
  files: RcFile[];
};

class FileUpload extends React.Component<Props, State> {
  state: State = {
    files: [],
  };
  action = (file: RcFile) => {
    this.state.files.push(file);
    console.log(this.state.files);
    return 'bleh';
  };

  uploaderFMProps = {
    // action: "https://httpbin.org/post",
    action: (file: RcFile) => {
      this.state.files.push(file);
      console.log(this.state.files);
      return 'bleh';
    },
    onStart: () => {
      console.log('>>> onStart');
    },
    onSuccess: () => {
      console.log('>>> onSuccess');
    },
  };

  render() {
    return (
      <RcUpload action={this.action}>
        <Button
          icon={<PaperClipOutlined />}
          type="ghost"
          style={{border: 'none', background: 'none'}}
        ></Button>
      </RcUpload>
    );
  }
}

export default FileUpload;
