import { Spinner } from 'react-bootstrap';

function LoadingSpinner({ text = 'Loading...' }) {
  return (
    <div className="loading-spinner">
      <div className="text-center">
        <Spinner animation="border" role="status" variant="primary">
          <span className="visually-hidden">Loading...</span>
        </Spinner>
        <p className="mt-3 text-muted">{text}</p>
      </div>
    </div>
  );
}

export default LoadingSpinner;
