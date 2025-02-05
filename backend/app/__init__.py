from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flask_cors import CORS

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()

def create_app():
    app = Flask(__name__)
    app.config.from_object('config.Config')

    CORS(app)
    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)

    from .routes import auth, overtime, admin
    app.register_blueprint(auth.bp)
    app.register_blueprint(overtime.bp)
    app.register_blueprint(admin.bp)

    return app
