import { Card, Badge } from 'react-bootstrap';
import { Link } from 'react-router-dom';
import { FiCalendar, FiUser } from 'react-icons/fi';

function UrshieCard({ urshie }) {
  const formatDate = (dateString) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  return (
    <Card className="urshie-card h-100">
      <Card.Body className="d-flex flex-column">
        <div className="d-flex justify-content-between align-items-start mb-2">
          <Card.Title as={Link} to={`/urshie/${urshie.id}`} className="text-decoration-none">
            {urshie.name}
          </Card.Title>
          {urshie.submission_count > 0 && (
            <Badge bg="secondary">{urshie.submission_count}</Badge>
          )}
        </div>
        
        <Card.Text className="urshie-description flex-grow-1">
          {urshie.description || 'No description provided'}
        </Card.Text>
        
        {urshie.tags && urshie.tags.length > 0 && (
          <div className="mb-3">
            {urshie.tags.slice(0, 5).map((tag, index) => (
              <span key={index} className="tag-badge">{tag}</span>
            ))}
            {urshie.tags.length > 5 && (
              <span className="tag-badge">+{urshie.tags.length - 5}</span>
            )}
          </div>
        )}
        
        <div className="urshie-meta">
          <span>
            <FiUser className="me-1" />
            {urshie.created_by}
          </span>
          <span>
            <FiCalendar className="me-1" />
            {formatDate(urshie.created_at)}
          </span>
        </div>
      </Card.Body>
    </Card>
  );
}

export default UrshieCard;
