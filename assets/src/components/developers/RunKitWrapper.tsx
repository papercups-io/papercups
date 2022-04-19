import React from 'react';
import {Box} from 'theme-ui';
import {DEFAULT_ENDPOINT_PREAMBLE, RunKit} from './RunKit';

const RunKitLoading = ({height}: {height: number}) => {
  return (
    <Box
      py={1}
      px={2}
      style={{
        border: '1px solid #e5e9ef',
        borderRadius: '3pt',
        color: '#625666',
        background: '#fff',
        minHeight: height,
      }}
    ></Box>
  );
};

type Props = {
  source?: string;
  mode?: string;
  minHeight: number;
  nodeVersion?: string;
  environment?: Array<{name: string; value: string}>;
  onLoad?: (data: any) => void;
  onURLChanged?: (data: any) => void;
  onResize?: (data: any) => void;
  onEvaluate?: (data: any, source: string) => void;
};

type State = {loading: boolean};

class RunKitWrapper extends React.Component<Props, State> {
  el: HTMLDivElement | null = null;
  notebook: any = null;

  state: State = {loading: true};

  componentDidMount() {
    const {minHeight} = this.props;
    const options = {
      ...this.props,
      element: this.el,
      preamble: DEFAULT_ENDPOINT_PREAMBLE,
      minHeight: Number.isFinite(minHeight) ? `${minHeight}px` : null,
      hidesEndpointLogs: true,
      onLoad: this.handleLoaded,
      onURLChanged: this.handleUrlChanged,
      onEvaluate: this.handleEvaluate,
      onResize: this.handleResize,
    };

    if (RunKit && typeof RunKit.createNotebook === 'function') {
      this.notebook = RunKit.createNotebook(options);
    }
  }

  componentWillUnmount() {
    this.notebook?.destroy();
    this.notebook = null;
  }

  handleLoaded = (data: any) => {
    this.setState({loading: false});
    this.props.onLoad && this.props.onLoad(data);
  };

  handleUrlChanged = (data: any) => {
    this.props.onURLChanged && this.props.onURLChanged(data);
  };

  handleResize = (data: any) => {
    this.props.onResize && this.props.onResize(data);
  };

  handleEvaluate = (data: any) => {
    this.getSource().then((source) => {
      this.props.onEvaluate && this.props.onEvaluate(data, source);
    });
  };

  evaluate(cb: any) {
    this.notebook?.evaluate(cb);
  }

  getSource(): Promise<string> {
    return this.notebook?.getSource();
  }

  getURL() {
    return this.notebook?.URL;
  }

  render() {
    const {minHeight} = this.props;

    return (
      <div
        ref={(el) => (this.el = el)}
        style={{overflow: 'hidden', paddingLeft: 20, marginLeft: -20}}
      >
        {this.state.loading && <RunKitLoading height={minHeight} />}
      </div>
    );
  }
}

export default RunKitWrapper;
